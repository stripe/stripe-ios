//
//  NetworkedIdentityCoordinator.swift
//  StripeIdentity
//

import Foundation
@_spi(STP) import StripeCore
import UIKit

@MainActor
protocol NetworkedIdentityCoordinatorDelegate: AnyObject {
    func networkedIdentityCoordinator(
        _ coordinator: NetworkedIdentityCoordinator,
        didTransitionTo state: NetworkedIdentityState
    )

    func networkedIdentityCoordinator(
        _ coordinator: NetworkedIdentityCoordinator,
        didFinishWith outcome: NetworkedIdentityOutcome
    )
}

/// Networked Identity on top of Link's login. Nothing starts or advances without a user action:
/// `startReuse()` from the intro, `startSave()` from the success screen, and sharing or continuing
/// always need a tap. A handed-in Link session or a known email only lets the flow skip the email or
/// one-time code steps.
@MainActor
final class NetworkedIdentityCoordinator {
    /// Why an attempt ended without a backend error, for the save failure details.
    fileprivate enum FlowError: Error {
        case missingConsumerCredentials
        case linkNotConfigured
        case noLinkUIHost
        case unexpectedVerificationResponse
    }

    fileprivate enum ConsumerErrorCode: String {
        case invalidCode = "consumer_verification_code_invalid"
        case verificationExpired = "consumer_verification_expired"
        case sessionExpired = "consumer_session_expired"
    }

    private static let otpLength = 6

    private let linkSession: NetworkedIdentityLinkSession
    private let apiClient: NetworkedIdentityAPIClient
    private let actions: NetworkedIdentityActions
    private let documentRequirements: NetworkedIdentityDocumentRequirements
    private let config: NetworkedIdentityConfig
    private let handoff: IdentityVerificationSheet.Configuration.LinkSessionHandoff?
    private let currentTime: () -> TimeInterval
    var onVerificationUpdate: ((StripeAPI.VerificationPageData) -> Void)?

    weak var delegate: NetworkedIdentityCoordinatorDelegate?
    /// Presents Link's own screens when `config.usesLinkUI` is set.
    weak var linkUIHost: UIViewController?

    /// Whether Identity's sheet stays hidden until Link's own screens have authenticated the user.
    var usesLinkUI: Bool { config.usesLinkUI }

    private(set) var state: NetworkedIdentityState = .idle
    private(set) var mode: NetworkedIdentityMode = .reuse
    private(set) var route: NetworkedIdentityRoute

    var hasPreparedSave: Bool { route == .resumeSave }

    var entry: NetworkedIdentityEntry {
        .init(config: config, handoff: handoff, route: route, accountEmail: account?.email)
    }

    var redactedFormattedPhoneNumber: String? {
        account?.redactedPhoneNumber
    }

    /// Identifies the current attempt. Responses from a cancelled or restarted attempt are ignored.
    private var attempt = 0
    private var configuration: Task<Bool, Never>?
    private var account: NetworkedIdentityLinkAccount?
    private var attached: StripeAPI.VerificationPageData?
    private var task: Task<Void, Never>?
    private var mutation: Task<StripeAPI.VerificationPageData, Error>?
    private var previewLookup: Task<NetworkedIdentityLinkAccount?, Error>?

    init(
        linkSession: NetworkedIdentityLinkSession,
        apiClient: NetworkedIdentityAPIClient,
        actions: NetworkedIdentityActions,
        documentRequirements: NetworkedIdentityDocumentRequirements,
        config: NetworkedIdentityConfig,
        handoff: IdentityVerificationSheet.Configuration.LinkSessionHandoff?,
        currentTime: @escaping () -> TimeInterval = { Date().timeIntervalSince1970 }
    ) {
        self.linkSession = linkSession
        self.apiClient = apiClient
        self.actions = actions
        self.documentRequirements = documentRequirements
        self.config = config
        self.route = config.route
        self.handoff = handoff
        self.currentTime = currentTime
    }

    func startReuse() {
        start(.reuse)
    }

    func startSave() {
        start(.save)
    }

    /// Looks up the provided email's Link account without sending a code or opening the sheet. Returns nil
    /// when a handed-in session already names the account, there's no email to check, or no account exists.
    func lookUpProvidedAccountEmail() async -> String? {
        guard entry.linkAvailable, handoff == nil,
              let email = config.merchantEmail, !email.isEmpty,
              let publishableKey = config.merchantPublishableKey, !publishableKey.isEmpty,
              !state.isSheetVisible
        else {
            return nil
        }
        if let account { return account.email }
        if previewLookup == nil {
            previewLookup = Task { [weak self, linkSession] in
                guard await self?.ensureConfigured(publishableKey: publishableKey) == true else {
                    throw FlowError.linkNotConfigured
                }
                try Task.checkCancellation()
                return try await linkSession.lookup(email: email)
            }
        }
        let startedAttempt = attempt
        let found = try? await previewLookup?.value
        if startedAttempt == attempt {
            account = found
        }
        return found?.email
    }

    func submitEmail(_ email: String) {
        guard state == .collectEmail || state == .reauthenticationRequired else {
            return
        }
        let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedEmail.isEmpty else {
            return
        }
        lookup(email: normalizedEmail)
    }

    func submitPhone(phoneNumber: String, country: String) {
        guard case .collectPhone(let email, _) = state, !phoneNumber.isEmpty, !country.isEmpty else {
            return
        }
        transition(to: .signUpPending(email: email))
        perform(
            { [linkSession] in
                try await linkSession.signUp(email: email, phoneNumber: phoneNumber, country: country, name: nil)
            },
            onSuccess: { [weak self] created in self?.onAccount(created) },
            onFailure: { [weak self] error in
                // Staying on the step keeps the reason visible; dismissing the sheet would hide it.
                self?.transition(to: .collectPhone(email: email, error: error.localizedDescription))
            }
        )
    }

    func submitOTP(_ code: String) {
        guard case .awaitingOTP = state,
              code.count == Self.otpLength,
              code.allSatisfy({ $0.isASCII && $0.isNumber }) else {
            return
        }
        transition(to: .otpConfirmPending)
        perform(
            { [linkSession] in try await linkSession.confirmVerification(code: code) },
            onSuccess: { [weak self] verified in
                self?.account = verified
                self?.proceedAuthenticated()
            },
            onFailure: { [weak self] error in self?.handleConfirmationError(error) }
        )
    }

    func resendOTP() {
        guard case .awaitingOTP = state else {
            return
        }
        sendCode(isResend: true)
    }

    func selectDocument(_ document: NetworkedIdentityDocument) {
        guard case .selectDocument(let documents, _) = state,
              documents.contains(where: { $0.id == document.id }) else {
            return
        }
        transition(to: .selectDocument(documents: documents, selectedDocumentID: document.id))
    }

    func shareSelectedDocument() {
        guard case .selectDocument(let documents, let selectedDocumentID) = state,
              let document = documents.first(where: { $0.id == selectedDocumentID }) else {
            return
        }
        guard let credentials = account?.credentials else {
            fallBack(.unavailable)
            return
        }
        transition(to: .sharingDocument(document))
        perform(
            { [weak self, apiClient, actions] in
                let token = try await Self.value(
                    of: apiClient.createAssociationToken(
                        identityDocumentID: document.id,
                        consumerSessionClientSecret: credentials.sessionClientSecret,
                        consumerPublishableKey: credentials.publishableKey
                    )
                )
                try Task.checkCancellation()
                guard let self else { throw CancellationError() }
                // Minted only after the explicit tap and redeemed once: association tokens are single-use.
                // #TODO - Networked Identity [NI-Contract]: recovery for ambiguous attach failures. Never replay a token.
                return try await self.mutate(route: .resumeReuse) {
                    try await actions.attachDocument(associationToken: token.associationToken)
                }
            },
            onSuccess: { [weak self] attached in
                self?.attached = attached
                self?.transition(to: .documentShared(document))
            },
            onFailure: { [weak self] error in self?.fallBack(.unavailable, error: error) }
        )
    }

    func continueAfterSuccess() {
        let outcome: NetworkedIdentityOutcome
        switch state {
        case .documentShared(let document):
            guard let attached else {
                return
            }
            outcome = .documentShared(document, attached: attached)
        case .savePrepared:
            outcome = .savePrepared
        default:
            return
        }
        attempt += 1
        transition(to: .idle)
        delegate?.networkedIdentityCoordinator(self, didFinishWith: outcome)
    }

    func chooseManualCapture() {
        guard mode == .reuse, state != .skipPending else {
            return
        }
        invalidateAttempt()
        transition(to: .skipPending)
        perform(
            { [weak self, actions] in
                guard let self else { throw CancellationError() }
                return try await self.mutate(route: .none) { try await actions.skip() }
            },
            onSuccess: { [weak self] updated in
                guard let self else { return }
                self.attached = nil
                self.transition(to: .idle)
                self.delegate?.networkedIdentityCoordinator(self, didFinishWith: .manualCapture(updated))
            },
            // Skip only records the choice. If it can't (e.g. the backend doesn't support Networked Identity for
            // this session yet), the user still continues with ordinary verification.
            onFailure: { [weak self] _ in
                guard let self else { return }
                self.transition(to: .idle)
                self.delegate?.networkedIdentityCoordinator(self, didFinishWith: .fallback(.unavailable))
            }
        )
    }

    func cancel() {
        guard state.isSheetVisible else {
            return
        }
        invalidateAttempt()
        transition(to: .cancelled)
        delegate?.networkedIdentityCoordinator(self, didFinishWith: .cancelled)
    }

    /// Ends pending UI work without an outcome. A handed-in Link session belongs to its original owner.
    func abandon() {
        invalidateAttempt()
        configuration?.cancel()
        previewLookup?.cancel()
        onVerificationUpdate = nil
        state = .cancelled
    }
}

// MARK: - Private

private extension NetworkedIdentityCoordinator {
    func start(_ newMode: NetworkedIdentityMode) {
        guard !state.isSheetVisible else {
            return
        }
        invalidateAttempt()
        mode = newMode
        guard let publishableKey = config.merchantPublishableKey, !publishableKey.isEmpty,
              newMode == .reuse ? entry.reuseAvailable : entry.offersSave else {
            fallBack(.unavailable)
            return
        }
        if newMode == .save, hasPreparedSave {
            transition(to: .savePrepared)
            return
        }
        transition(to: .preparing)
        perform(
            { [weak self] in await self?.ensureConfigured(publishableKey: publishableKey) ?? false },
            onSuccess: { [weak self] ready in
                if ready {
                    self?.continueAfterConfiguration()
                } else {
                    self?.fallBack(.unavailable, error: FlowError.linkNotConfigured)
                }
            },
            onFailure: { [weak self] error in self?.fallBack(.unavailable, error: error) }
        )
    }

    /// Configures Link once; concurrent callers share the same attempt, and a failure allows a retry.
    func ensureConfigured(publishableKey: String) async -> Bool {
        let pending = configuration ?? Task { [linkSession] in
            (try? await linkSession.configure(merchantPublishableKey: publishableKey)) != nil
        }
        configuration = pending
        let ready = await pending.value
        if !ready {
            configuration = nil
        }
        return ready
    }

    func continueAfterConfiguration() {
        if config.usesLinkUI, handoff == nil, account?.isVerified != true {
            authenticateWithLinkUI(email: config.merchantEmail)
            return
        }
        if let account {
            onAccount(account)
            return
        }
        if let previewLookup {
            perform(
                { try await previewLookup.value },
                onSuccess: { [weak self] found in
                    self?.previewLookup = nil
                    self?.onLookup(found)
                },
                onFailure: { [weak self] _ in
                    self?.previewLookup = nil
                    self?.continueWithEmail(self?.config.merchantEmail)
                }
            )
            return
        }
        guard let handoff else {
            continueWithEmail(config.merchantEmail)
            return
        }
        let credentials = NetworkedIdentityConsumerCredentials(
            publishableKey: handoff.consumerPublishableKey,
            sessionClientSecret: handoff.consumerSessionClientSecret
        )
        perform(
            { [linkSession] in try await linkSession.restore(credentials: credentials) },
            onSuccess: { [weak self] restored in self?.onAccount(restored) },
            // An expired or invalid handed-in session only loses the shortcut.
            onFailure: { [weak self] _ in self?.continueWithEmail(handoff.email) }
        )
    }

    func continueWithEmail(_ knownEmail: String?) {
        if config.usesLinkUI {
            authenticateWithLinkUI(email: knownEmail)
            return
        }
        guard let knownEmail, !knownEmail.isEmpty else {
            transition(to: .collectEmail)
            return
        }
        lookup(email: knownEmail)
    }

    func lookup(email: String) {
        transition(to: .lookupPending)
        perform(
            { [linkSession] in try await linkSession.lookup(email: email) },
            onSuccess: { [weak self] found in self?.onLookup(found, email: email) },
            onFailure: { [weak self] error in self?.fallBack(.unavailable, error: error) }
        )
    }

    func onLookup(_ found: NetworkedIdentityLinkAccount?, email: String? = nil) {
        if let found {
            onAccount(found)
        } else if mode == .save, let email = email ?? config.merchantEmail {
            transition(to: .collectPhone(email: email, error: nil))
        } else {
            fallBack(.noLinkAccount)
        }
    }

    func onAccount(_ found: NetworkedIdentityLinkAccount) {
        account = found
        if found.isVerified {
            proceedAuthenticated()
        } else if config.usesLinkUI {
            authenticateWithLinkUI(email: found.email)
        } else {
            sendCode(isResend: false)
        }
    }

    /// Hands sign-in, sign-up and code verification to Link's own screens, then continues in Identity's sheet.
    func authenticateWithLinkUI(email: String?) {
        guard let host = linkUIHost else {
            fallBack(.unavailable, error: FlowError.noLinkUIHost)
            return
        }
        transition(to: .linkAuthentication)
        let mode = mode
        perform(
            { [linkSession] in
                try await linkSession.authenticateWithLinkUI(email: email, mode: mode, from: host)
            },
            onSuccess: { [weak self] account in
                guard let self else { return }
                guard let account else {
                    self.cancel()
                    return
                }
                self.account = account
                self.proceedAuthenticated()
            },
            onFailure: { [weak self] error in self?.fallBack(.unavailable, error: error) }
        )
    }

    func sendCode(isResend: Bool) {
        transition(to: .otpStartPending)
        perform(
            { [linkSession] in try await linkSession.startVerification(isResend: isResend) },
            onSuccess: { [weak self] updated in
                self?.account = updated
                self?.transition(to: .awaitingOTP(invalidCode: false))
            },
            onFailure: { [weak self] error in
                if Self.consumerErrorCode(of: error) == .sessionExpired {
                    self?.requireReauthentication()
                } else {
                    self?.fallBack(.unavailable, error: error)
                }
            }
        )
    }

    func handleConfirmationError(_ error: Error) {
        switch Self.consumerErrorCode(of: error) {
        case .invalidCode:
            transition(to: .awaitingOTP(invalidCode: true))
        case .verificationExpired:
            sendCode(isResend: false)
        case .sessionExpired:
            requireReauthentication()
        case nil:
            fallBack(.unavailable, error: error)
        }
    }

    func proceedAuthenticated() {
        guard let credentials = account?.credentials else {
            fallBack(.unavailable, error: FlowError.missingConsumerCredentials)
            return
        }
        switch mode {
        case .reuse:
            loadDocuments(credentials: credentials)
        case .save:
            recordSaveConsent(credentials: credentials)
        }
    }

    func loadDocuments(credentials: NetworkedIdentityConsumerCredentials) {
        transition(to: .documentsPending)
        perform(
            { [apiClient] in
                try await Self.value(
                    of: apiClient.listIdentityDocuments(
                        consumerSessionClientSecret: credentials.sessionClientSecret,
                        consumerPublishableKey: credentials.publishableKey
                    )
                )
            },
            onSuccess: { [weak self] response in
                guard let self else {
                    return
                }
                let now = self.currentTime()
                let eligible = response.data.filter { self.documentRequirements.allows($0, at: now) }
                guard !eligible.isEmpty else {
                    self.fallBack(.noReusableDocuments)
                    return
                }
                // Sharing always needs an explicit tap; a single document is only preselected.
                self.transition(
                    to: .selectDocument(
                        documents: eligible,
                        selectedDocumentID: eligible.count == 1 ? eligible.first?.id : nil
                    )
                )
            },
            onFailure: { [weak self] error in self?.fallBack(.unavailable, error: error) }
        )
    }

    func recordSaveConsent(credentials: NetworkedIdentityConsumerCredentials) {
        transition(to: .savePending)
        perform(
            { [weak self, apiClient, actions] in
                // #TODO - Networked Identity [NI-Contract]: confirm prepare_document_save is accepted after the
                // verification is submitted; the design hasn't settled whether saving is offered before or after capture.
                let token = try await Self.value(
                    of: apiClient.createSaveAssociationToken(
                        verificationSessionID: actions.verificationSessionID,
                        consumerSessionClientSecret: credentials.sessionClientSecret,
                        consumerPublishableKey: credentials.publishableKey
                    )
                )
                try Task.checkCancellation()
                guard let self else { throw CancellationError() }
                return try await self.mutate(route: .resumeSave) {
                    try await actions.prepareDocumentSave(associationToken: token.associationToken)
                }
            },
            onSuccess: { [weak self] _ in
                self?.transition(to: .savePrepared)
            },
            onFailure: { [weak self] error in self?.fallBack(.unavailable, error: error) }
        )
    }

    func requireReauthentication() {
        account = nil
        previewLookup = nil
        transition(to: .reauthenticationRequired)
    }

    func fallBack(_ reason: NetworkedIdentityFallbackReason, error: Error? = nil) {
        switch state {
        case .cancelled, .fullCaptureFallback, .saveFailed:
            return
        default:
            break
        }
        invalidateAttempt()
        // Saving has no capture to fall back to: keep the sheet open and say what went wrong.
        if mode == .save {
            transition(to: .saveFailed(details: error.map(Self.details(of:))))
            return
        }
        transition(to: .fullCaptureFallback(reason))
        delegate?.networkedIdentityCoordinator(self, didFinishWith: .fallback(reason))
    }

    func transition(to newState: NetworkedIdentityState) {
        state = newState
        delegate?.networkedIdentityCoordinator(self, didTransitionTo: newState)
    }

    func invalidateAttempt() {
        attempt += 1
        task?.cancel()
        task = nil
    }

    func mutate(
        route: NetworkedIdentityRoute,
        _ operation: @escaping () async throws -> StripeAPI.VerificationPageData
    ) async throws -> StripeAPI.VerificationPageData {
        // A request already sent can still commit after cancellation. Every later write waits for it.
        _ = await mutation?.result
        try Task.checkCancellation()
        let pending = Task { [weak self, actions] in
            let updated = try await operation()
            guard updated.id == actions.verificationSessionID, updated.requirements.errors.isEmpty,
                  updated.status != .canceled else {
                throw FlowError.unexpectedVerificationResponse
            }
            // Dismissing the Link UI cannot undo a committed write. Keep the host's requirements current.
            self?.route = route
            self?.onVerificationUpdate?(updated)
            return updated
        }
        mutation = pending
        return try await pending.value
    }

    /// Runs `operation` and delivers its result only if the attempt that started it is still current.
    func perform<Value>(
        _ operation: @escaping () async throws -> Value,
        onSuccess: @escaping (Value) -> Void,
        onFailure: @escaping (Error) -> Void
    ) {
        let startedAttempt = attempt
        task = Task { @MainActor [weak self] in
            let result: Result<Value, Error>
            do {
                result = .success(try await operation())
            } catch {
                result = .failure(error)
            }
            guard let self, !Task.isCancelled, startedAttempt == self.attempt else {
                return
            }
            self.task = nil
            switch result {
            case .success(let value):
                onSuccess(value)
            case .failure(let error):
                onFailure(error)
            }
        }
    }

    static func details(of error: Error) -> String {
        guard let code = error._stp_error_code else {
            return String(describing: error)
        }
        return "\(error.localizedDescription) (\(code))"
    }

    static func consumerErrorCode(of error: Error) -> ConsumerErrorCode? {
        ConsumerErrorCode(rawValue: error._stp_error_code ?? "")
    }

    static func value<Value>(of future: Future<Value>) async throws -> Value {
        try await withCheckedThrowingContinuation { continuation in
            future.observe(on: .main) { result in
                continuation.resume(with: result)
            }
        }
    }
}
