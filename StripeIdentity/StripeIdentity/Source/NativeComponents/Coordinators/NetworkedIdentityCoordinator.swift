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

    /// A committed write changed `entry`. It can land after the attempt that issued it was closed.
    func networkedIdentityCoordinatorDidChangeRoute(_ coordinator: NetworkedIdentityCoordinator)
}

/// Networked Identity on top of Link's login. Nothing starts or advances without a user action:
/// `startReuse()` from the intro, `startSave()` from the success screen, and sharing or continuing
/// always need a tap. Sign-in always uses Link's own screens: a verified handed-in Link session skips
/// them, and a known email only prefills them.
@MainActor
final class NetworkedIdentityCoordinator {
    /// Why an attempt ended without a backend error, for the save failure details.
    fileprivate enum FlowError: Error {
        case missingConsumerCredentials
        case linkNotConfigured
        case noLinkUIHost
        case unexpectedVerificationResponse
    }

    private static let networkedIdentityUnavailableCode = "networked_identity_unavailable"

    private let linkSession: NetworkedIdentityLinkSession
    private let apiClient: NetworkedIdentityAPIClient
    private let actions: NetworkedIdentityActions
    private let documentRequirements: NetworkedIdentityDocumentRequirements
    private let config: NetworkedIdentityConfig
    private let handoff: IdentityVerificationSheet.Configuration.LinkSessionHandoff?
    private let currentTime: () -> TimeInterval
    /// Records a committed verification in the host, which returns false for one that doesn't apply to this session.
    var onVerificationUpdate: ((StripeAPI.VerificationPageData) -> Bool)?

    weak var delegate: NetworkedIdentityCoordinatorDelegate?
    /// Presents Link's own sign-in and sign-up screens.
    weak var linkUIHost: UIViewController?

    private(set) var state: NetworkedIdentityState = .idle
    private(set) var mode: NetworkedIdentityMode = .reuse
    private(set) var route: NetworkedIdentityRoute {
        didSet { delegate?.networkedIdentityCoordinatorDidChangeRoute(self) }
    }

    var entry: NetworkedIdentityEntry {
        .init(config: config, handoff: handoff, route: route, accountEmail: account?.email)
    }

    /// Identifies the current attempt. Responses from a cancelled or restarted attempt are ignored.
    private var attempt = 0
    private var configuration: Task<Bool, Never>?
    private var account: NetworkedIdentityLinkAccount?
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
        guard entry.reuseAvailable, handoff == nil,
              let email = config.merchantEmail, !email.isEmpty,
              let publishableKey = config.merchantPublishableKey, !publishableKey.isEmpty,
              !state.isInProgress
        else {
            return nil
        }
        if let account { return account.email }
        // Concurrent callers share the same lookup, and a failure allows a retry.
        let lookup = previewLookup ?? Task { [weak self, linkSession] in
            guard await self?.ensureConfigured(publishableKey: publishableKey) == true else {
                throw FlowError.linkNotConfigured
            }
            try Task.checkCancellation()
            return try await linkSession.lookup(email: email)
        }
        previewLookup = lookup
        let startedAttempt = attempt
        let result = await lookup.result
        if case .failure = result {
            previewLookup = nil
        }
        let found = try? result.get()
        if startedAttempt == attempt {
            account = found
        }
        return found?.email
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
            fallBack()
            return
        }
        transition(to: .sharingDocument(document))
        perform(
            { [weak self, apiClient, actions] in
                guard let self else { throw CancellationError() }
                // Minted only after the explicit tap.
                return try await self.redeem(
                    route: .resumeReuse,
                    mint: {
                        try await apiClient.createAssociationToken(
                            identityDocumentID: document.id,
                            verificationSessionID: actions.verificationSessionID,
                            consumerSessionClientSecret: credentials.sessionClientSecret,
                            consumerPublishableKey: credentials.publishableKey
                        ).value.associationToken
                    },
                    using: { token in try await actions.attachDocument(associationToken: token) }
                )
            },
            onSuccess: { [weak self] _ in self?.transition(to: .documentShared(document)) },
            onFailure: { [weak self] error in self?.fallBack(error: error) }
        )
    }

    func continueAfterSuccess() {
        let outcome: NetworkedIdentityOutcome
        switch state {
        case .documentShared:
            outcome = .documentShared
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
            onSuccess: { [weak self] _ in
                guard let self else { return }
                self.transition(to: .idle)
                self.delegate?.networkedIdentityCoordinator(self, didFinishWith: .manualCapture)
            },
            // Skip only records the choice. If it can't (e.g. the backend doesn't support Networked Identity for
            // this session yet), the user still continues with ordinary verification.
            onFailure: { [weak self] _ in
                guard let self else { return }
                self.transition(to: .idle)
                self.delegate?.networkedIdentityCoordinator(self, didFinishWith: .fallback)
            }
        )
    }

    func cancel() {
        guard state.isInProgress else {
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
        guard !state.isInProgress else {
            return
        }
        invalidateAttempt()
        mode = newMode
        guard let publishableKey = config.merchantPublishableKey, !publishableKey.isEmpty,
              newMode == .reuse ? entry.reuseAvailable : entry.offersSave else {
            fallBack()
            return
        }
        transition(to: .preparing)
        perform(
            { [weak self] in await self?.ensureConfigured(publishableKey: publishableKey) ?? false },
            onSuccess: { [weak self] ready in
                if ready {
                    self?.continueAfterConfiguration()
                } else {
                    self?.fallBack(error: FlowError.linkNotConfigured)
                }
            },
            onFailure: { [weak self] error in self?.fallBack(error: error) }
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
        if let account {
            onAccount(account)
            return
        }
        guard let handoff else {
            authenticateWithLinkUI(email: config.merchantEmail)
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
            onFailure: { [weak self] _ in self?.authenticateWithLinkUI(email: handoff.email) }
        )
    }

    func onAccount(_ found: NetworkedIdentityLinkAccount) {
        account = found
        if found.isVerified {
            proceedAuthenticated()
        } else {
            authenticateWithLinkUI(email: found.email)
        }
    }

    /// Hands sign-in, sign-up and code verification to Link's own screens, then continues in Identity's sheet.
    func authenticateWithLinkUI(email: String?) {
        guard let host = linkUIHost else {
            fallBack(error: FlowError.noLinkUIHost)
            return
        }
        transition(to: .linkAuthentication)
        let mode = mode
        let phoneNumber = config.phoneNumberAutofillHint
        perform(
            { [linkSession] in
                try await linkSession.authenticateWithLinkUI(
                    email: email,
                    phoneNumber: phoneNumber,
                    mode: mode,
                    from: host
                )
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
            onFailure: { [weak self] error in self?.fallBack(error: error) }
        )
    }

    func proceedAuthenticated() {
        guard let credentials = account?.credentials else {
            fallBack(error: FlowError.missingConsumerCredentials)
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
                try await apiClient.listIdentityDocuments(
                    consumerSessionClientSecret: credentials.sessionClientSecret,
                    consumerPublishableKey: credentials.publishableKey
                ).value
            },
            onSuccess: { [weak self] response in
                guard let self else {
                    return
                }
                let now = self.currentTime()
                let eligible = response.data.filter { self.documentRequirements.allows($0, at: now) }
                guard !eligible.isEmpty else {
                    self.fallBack()
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
            onFailure: { [weak self] error in self?.fallBack(error: error) }
        )
    }

    func recordSaveConsent(credentials: NetworkedIdentityConsumerCredentials) {
        transition(to: .savePending)
        perform(
            { [weak self, apiClient, actions] in
                // #TODO - Networked Identity [NI-Contract]: confirm prepare_document_save is accepted after the
                // verification is submitted; the design hasn't settled whether saving is offered before or after capture.
                guard let self else { throw CancellationError() }
                return try await self.redeem(
                    route: .resumeSave,
                    mint: {
                        try await apiClient.createSaveAssociationToken(
                            verificationSessionID: actions.verificationSessionID,
                            consumerSessionClientSecret: credentials.sessionClientSecret,
                            consumerPublishableKey: credentials.publishableKey
                        ).value.associationToken
                    },
                    using: { token in try await actions.prepareDocumentSave(associationToken: token) }
                )
            },
            onSuccess: { [weak self] _ in
                self?.transition(to: .savePrepared)
            },
            onFailure: { [weak self] error in self?.fallBack(error: error) }
        )
    }

    func fallBack(error: Error? = nil) {
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
        transition(to: .fullCaptureFallback)
        delegate?.networkedIdentityCoordinator(self, didFinishWith: .fallback)
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
        let pending = Task { [weak self] in
            let updated = try await operation()
            // Dismissing the Link UI cannot undo a committed write. Keep the host's requirements current.
            guard self?.onVerificationUpdate?(updated) == true else {
                throw FlowError.unexpectedVerificationResponse
            }
            self?.route = route
            return updated
        }
        mutation = pending
        return try await pending.value
    }

    /// Mints a single-use token and redeems it. When the redemption is rejected or its response is lost, the
    /// session is read back first, because the write may have committed; otherwise one fresh token is minted and
    /// redeemed. If it can't be read back, the redemption fails rather than risk a second write. A token is never
    /// replayed.
    func redeem(
        route: NetworkedIdentityRoute,
        mint: @escaping () async throws -> String,
        using redemption: @escaping (String) async throws -> StripeAPI.VerificationPageData
    ) async throws -> StripeAPI.VerificationPageData {
        var retriesLeft = 1
        while true {
            try Task.checkCancellation()
            let token = try await mint()
            try Task.checkCancellation()
            do {
                return try await mutate(route: route) { try await redemption(token) }
            } catch {
                guard Self.mayRetryRedemption(after: error) else {
                    throw error
                }
                if let committed = try await actions.verificationIfCommitted(route) {
                    return try await mutate(route: route) { committed }
                }
                guard retriesLeft > 0 else {
                    throw error
                }
                retriesLeft -= 1
            }
        }
    }

    /// Whether a failed redemption may be retried with a fresh token: the token was rejected (400) or already
    /// used (429), or the response was lost and the write may have committed.
    static func mayRetryRedemption(after error: Error) -> Bool {
        if error is CancellationError || error is FlowError {
            return false
        }
        guard case StripeError.apiError(let apiError) = error else {
            // No Stripe error came back: the response was lost or unreadable.
            return true
        }
        guard apiError.code != networkedIdentityUnavailableCode else {
            return false
        }
        guard let status = apiError.httpStatusCode else {
            return true
        }
        return status == 400 || status == 429 || status >= 500
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
}
