//
//  NetworkedIdentityCoordinator.swift
//  StripeIdentity
//

import Foundation
@_spi(STP) import StripeCore

@MainActor
protocol NetworkedIdentityCoordinatorDelegate: AnyObject {
    func networkedIdentityCoordinator(
        _ coordinator: NetworkedIdentityCoordinator,
        didTransitionTo state: NetworkedIdentityState
    )

    func networkedIdentityCoordinatorDidRequestFullCaptureFallback(
        _ coordinator: NetworkedIdentityCoordinator
    )
}

/// Coordinates the Link lookup and authentication work that can safely happen before document reuse.
@MainActor
final class NetworkedIdentityCoordinator {
    private enum ConsumerErrorCode: String {
        case invalidCode = "consumer_verification_code_invalid"
        case verificationExpired = "consumer_verification_expired"
        case sessionExpired = "consumer_session_expired"
        case maxAttemptsExceeded = "consumer_verification_max_attempts_exceeded"
    }

    private let apiClient: NetworkedIdentityAPIClient
    private let documentRequirements: NetworkedIdentityDocumentRequirements
    private let credentialStore: NetworkedIdentityCredentialStore
    private let currentTime: () -> TimeInterval
    private var activeSMSVerificationSessionID: String?
    private var knownSMSVerificationSessionIDs: Set<String> = []

    weak var delegate: NetworkedIdentityCoordinatorDelegate?

    private(set) var state: NetworkedIdentityState = .collectEmail
    private(set) var lastOTPError: NetworkedIdentityOTPError?
    private(set) var fallbackReason: NetworkedIdentityFallbackReason?
    private(set) var availableDocuments: [NetworkedIdentityDocument] = []
    private(set) var selectedDocument: NetworkedIdentityDocument?
    private(set) var emailAddress: String?
    private(set) var redactedFormattedPhoneNumber: String?

    init(
        apiClient: NetworkedIdentityAPIClient,
        documentRequirements: NetworkedIdentityDocumentRequirements,
        verificationSessionClientSecrets: [String]? = nil,
        credentialStore: NetworkedIdentityCredentialStore? = nil,
        currentTime: @escaping () -> TimeInterval = { Date().timeIntervalSince1970 }
    ) {
        self.apiClient = apiClient
        self.documentRequirements = documentRequirements
        self.currentTime = currentTime
        self.credentialStore = credentialStore
            ?? NetworkedIdentityCredentialStore(
                verificationSessionClientSecrets: verificationSessionClientSecrets
            )
    }

    func start(emailAddress: String) {
        guard state == .collectEmail || state == .reauthenticationRequired else {
            return
        }
        self.emailAddress = emailAddress
        beginLookup()
    }

    func submitOTP(_ code: String) {
        guard state == .awaitingOTP else {
            return
        }

        lastOTPError = nil
        guard let request = credentialStore.readConsumerCredentials({ credentials, verificationSessionClientSecrets in
            return (
                NetworkedIdentityConfirmVerificationRequest(
                    consumerSessionClientSecret: credentials.sessionClientSecret,
                    code: code,
                    type: .sms,
                    verificationSessionClientSecrets: verificationSessionClientSecrets
                ),
                credentials.publishableKey
            )
        }) else {
            fallBackToFullCapture(reason: .unavailable)
            return
        }

        let confirmation = apiClient.confirmVerification(
            request: request.0,
            consumerPublishableKey: request.1
        )
        transition(to: .otpConfirmPending)
        confirmation.observe(on: .main) { [weak self, apiClient] result in
            guard let self else {
                Self.logOutSuccessfulResponse(
                    result,
                    using: apiClient,
                    consumerPublishableKey: request.1,
                    verificationSessionClientSecrets: request.0.verificationSessionClientSecrets
                )
                return
            }
            guard self.state == .otpConfirmPending else {
                self.logOutIfFlowEnded(
                    result,
                    consumerPublishableKey: request.1,
                    verificationSessionClientSecrets: request.0.verificationSessionClientSecrets
                )
                return
            }

            switch result {
            case .success(let response):
                self.credentialStore.retainAuthSessionClientSecret(
                    response.authSessionClientSecret
                )
                self.redactedFormattedPhoneNumber =
                    response.consumerSession.redactedFormattedPhoneNumber
                self.credentialStore.updateConsumerSessionClientSecret(
                    response.consumerSession.clientSecret
                )
                if let activeSMSVerificationSessionID = self.activeSMSVerificationSessionID,
                   response.consumerSession.verificationSessions.contains(where: {
                       $0.id == activeSMSVerificationSessionID
                           && $0.type == .sms
                           && $0.state == .verified
                   }) {
                    self.activeSMSVerificationSessionID = nil
                    self.loadIdentityDocuments()
                } else {
                    self.fallBackToFullCapture(reason: .unavailable)
                }
            case .failure(let error):
                self.handleOTPError(error)
            }
        }
    }

    func resendOTP() {
        guard state == .awaitingOTP else {
            return
        }
        beginFreshSMSVerification(isResendingSMSCode: true)
    }

    func selectDocument(_ document: NetworkedIdentityDocument) {
        guard state == .selectDocument || state == .selectedDocument,
              let selectedDocument = availableDocuments.first(where: { $0.id == document.id }) else {
            return
        }

        self.selectedDocument = selectedDocument
        transition(to: .selectedDocument)

        // #TODO - Networked Identity: Define cloneConsumerIdentityDocument and association-token sequencing before completing reuse. The existing welcome screen discloses sharing verification data; granular requested-attribute metadata is not required.
    }

    func chooseManualCapture() {
        guard state != .cancelled, state != .fullCaptureFallback else {
            return
        }
        fallBackToFullCapture(reason: .userSelectedManualCapture)
    }

    func cancel() {
        endAsCancelled(notifyDelegate: true)
    }

    /// Cleans up an unfinished flow without notifying UI delegates when its owner is released.
    func abandon() {
        guard !flowHasEnded else {
            return
        }
        endAsCancelled(notifyDelegate: false)
    }
}

// MARK: - Private

private extension NetworkedIdentityCoordinator {
    func endAsCancelled(notifyDelegate: Bool) {
        guard state != .cancelled else {
            return
        }

        // Cancelling must not submit save consent or attempt to undo a previously saved document.
        let logout = credentialStore.readConsumerCredentials { credentials, verificationSessionClientSecrets in
            apiClient.logOut(
                consumerSessionClientSecret: credentials.sessionClientSecret,
                verificationSessionClientSecrets: verificationSessionClientSecrets,
                consumerPublishableKey: credentials.publishableKey
            )
        }

        credentialStore.clear()
        emailAddress = nil
        redactedFormattedPhoneNumber = nil
        activeSMSVerificationSessionID = nil
        knownSMSVerificationSessionIDs = []
        lastOTPError = nil
        fallbackReason = nil
        availableDocuments = []
        selectedDocument = nil
        if notifyDelegate {
            transition(to: .cancelled)
        } else {
            state = .cancelled
        }

        // Logout is best effort. Local credentials have already been cleared.
        logout?.observe { _ in }
    }

    func beginLookup() {
        guard let emailAddress else {
            fallBackToFullCapture(reason: .unavailable)
            return
        }

        lastOTPError = nil
        let verificationSessionClientSecrets = credentialStore.readVerificationSessionClientSecrets { $0 }
        let lookup = apiClient.lookupConsumer(
            emailAddress: emailAddress,
            verificationSessionClientSecrets: verificationSessionClientSecrets
        )

        transition(to: .lookupPending)
        lookup.observe(on: .main) { [weak self, apiClient] result in
            guard let self else {
                if case .success(.found(let response)) = result {
                    Self.bestEffortLogOut(
                        using: apiClient,
                        consumerSessionClientSecret: response.consumerSession.clientSecret,
                        consumerPublishableKey: response.publishableKey,
                        verificationSessionClientSecrets: NetworkedIdentityCredentialStore.appending(
                            response.authSessionClientSecret,
                            to: verificationSessionClientSecrets
                        )
                    )
                }
                return
            }
            guard self.state == .lookupPending else {
                if self.flowHasEnded,
                   case .success(.found(let response)) = result {
                    self.bestEffortLogOut(
                        consumerSessionClientSecret: response.consumerSession.clientSecret,
                        consumerPublishableKey: response.publishableKey,
                        verificationSessionClientSecrets: NetworkedIdentityCredentialStore.appending(
                            response.authSessionClientSecret,
                            to: verificationSessionClientSecrets
                        )
                    )
                }
                return
            }

            switch result {
            case .success(.found(let response)):
                self.credentialStore.retainAuthSessionClientSecret(
                    response.authSessionClientSecret
                )
                self.redactedFormattedPhoneNumber =
                    response.consumerSession.redactedFormattedPhoneNumber
                self.credentialStore.storeConsumerCredentials(
                    publishableKey: response.publishableKey,
                    sessionClientSecret: response.consumerSession.clientSecret
                )
                self.knownSMSVerificationSessionIDs = self.smsVerificationSessionIDs(
                    in: response.consumerSession
                )
                // Networked Identity always requires a fresh SMS verification, even if the
                // returned consumer session contains an older VERIFIED entry.
                self.beginFreshSMSVerification()
            case .success(.notFound):
                self.fallBackToFullCapture(reason: .noLinkAccount)
            case .failure:
                self.fallBackToFullCapture(reason: .unavailable)
            }
        }
    }

    func beginFreshSMSVerification(isResendingSMSCode: Bool = false) {
        let resendVerificationSessionID = isResendingSMSCode ? activeSMSVerificationSessionID : nil
        activeSMSVerificationSessionID = nil
        let knownSMSVerificationSessionIDs = knownSMSVerificationSessionIDs
        guard let request = credentialStore.readConsumerCredentials({ credentials, verificationSessionClientSecrets in
            return (
                NetworkedIdentityStartVerificationRequest(
                    consumerSessionClientSecret: credentials.sessionClientSecret,
                    type: .sms,
                    locale: Locale.current.toLanguageTag(),
                    accountPhoneNumber: nil,
                    verificationSessionClientSecrets: verificationSessionClientSecrets,
                    isResendingSMSCode: isResendingSMSCode
                ),
                credentials.publishableKey
            )
        }) else {
            fallBackToFullCapture(reason: .unavailable)
            return
        }

        let startVerification = apiClient.startVerification(
            request: request.0,
            consumerPublishableKey: request.1
        )
        transition(to: .otpStartPending)
        startVerification.observe(on: .main) { [weak self, apiClient] result in
            guard let self else {
                Self.logOutSuccessfulResponse(
                    result,
                    using: apiClient,
                    consumerPublishableKey: request.1,
                    verificationSessionClientSecrets: request.0.verificationSessionClientSecrets
                )
                return
            }
            guard self.state == .otpStartPending else {
                self.logOutIfFlowEnded(
                    result,
                    consumerPublishableKey: request.1,
                    verificationSessionClientSecrets: request.0.verificationSessionClientSecrets
                )
                return
            }

            switch result {
            case .success(let response):
                self.credentialStore.retainAuthSessionClientSecret(
                    response.authSessionClientSecret
                )
                self.redactedFormattedPhoneNumber =
                    response.consumerSession.redactedFormattedPhoneNumber
                self.credentialStore.updateConsumerSessionClientSecret(
                    response.consumerSession.clientSecret
                )
                let startedSMSSessions = response.consumerSession.verificationSessions.filter {
                    guard $0.type == .sms,
                          $0.state == .started,
                          let id = $0.id else {
                        return false
                    }
                    return !knownSMSVerificationSessionIDs.contains(id)
                }
                // Explicit resend may keep the active SMS session ID. Prefer a new ID if one
                // is returned, and never accept any unrelated historical verification session.
                let retainedSMSSessions = response.consumerSession.verificationSessions.filter {
                    $0.id == resendVerificationSessionID && $0.type == .sms && $0.state == .started
                }
                let eligibleSMSSessions = startedSMSSessions.isEmpty && resendVerificationSessionID != nil
                    ? retainedSMSSessions
                    : startedSMSSessions
                // #TODO - Networked Identity: Verify resend's same-ID/replacement-ID behavior against the web flow and an NI-enabled backend. Initial and expired-code starts still require a new ID.
                self.knownSMSVerificationSessionIDs.formUnion(
                    self.smsVerificationSessionIDs(in: response.consumerSession)
                )
                guard eligibleSMSSessions.count == 1,
                      let verificationSessionID = eligibleSMSSessions[0].id,
                      !verificationSessionID.isEmpty else {
                    self.fallBackToFullCapture(reason: .unavailable)
                    return
                }
                self.activeSMSVerificationSessionID = verificationSessionID
                self.lastOTPError = nil
                self.transition(to: .awaitingOTP)
            case .failure(let error):
                if ConsumerErrorCode(rawValue: error._stp_error_code ?? "") == .sessionExpired {
                    self.requireReauthentication()
                } else {
                    self.fallBackToFullCapture(reason: .unavailable)
                }
            }
        }
    }

    func loadIdentityDocuments() {
        guard let request = credentialStore.readConsumerCredentials({ credentials, _ in
            return (credentials.sessionClientSecret, credentials.publishableKey)
        }) else {
            fallBackToFullCapture(reason: .unavailable)
            return
        }

        let documentList = apiClient.listIdentityDocuments(
            consumerSessionClientSecret: request.0,
            consumerPublishableKey: request.1
        )
        transition(to: .documentsPending)
        documentList.observe(on: .main) { [weak self] result in
            guard let self, self.state == .documentsPending else {
                return
            }

            switch result {
            case .success(let response):
                let now = self.currentTime()
                let reusableDocuments = response.data.filter { document in
                    self.documentRequirements.allows(document, at: now)
                }
                if reusableDocuments.isEmpty {
                    self.fallBackToFullCapture(reason: .noReusableDocuments)
                } else {
                    self.availableDocuments = reusableDocuments
                    self.transition(to: .selectDocument)
                }
            case .failure:
                self.fallBackToFullCapture(reason: .unavailable)
            }
        }
    }

    func handleOTPError(_ error: Error) {
        switch ConsumerErrorCode(rawValue: error._stp_error_code ?? "") {
        case .invalidCode:
            lastOTPError = .invalidCode
            transition(to: .awaitingOTP)
        case .verificationExpired:
            lastOTPError = .verificationExpired
            beginFreshSMSVerification()
        case .sessionExpired:
            requireReauthentication()
        case .maxAttemptsExceeded:
            lastOTPError = .maxAttemptsExceeded
            fallBackToFullCapture(reason: .unavailable)
        case nil:
            fallBackToFullCapture(reason: .unavailable)
        }
    }

    func fallBackToFullCapture(reason: NetworkedIdentityFallbackReason) {
        // #TODO - Networked Identity: Skip and manual capture share the dedicated networking_data clear API; wire it here once the request/response contract is available.
        let logout = credentialStore.readConsumerCredentials { credentials, verificationSessionClientSecrets in
            apiClient.logOut(
                consumerSessionClientSecret: credentials.sessionClientSecret,
                verificationSessionClientSecrets: verificationSessionClientSecrets,
                consumerPublishableKey: credentials.publishableKey
            )
        }

        credentialStore.clear()
        emailAddress = nil
        redactedFormattedPhoneNumber = nil
        activeSMSVerificationSessionID = nil
        knownSMSVerificationSessionIDs = []
        fallbackReason = reason
        availableDocuments = []
        selectedDocument = nil
        transition(to: .fullCaptureFallback)
        guard state == .fullCaptureFallback else {
            return
        }
        delegate?.networkedIdentityCoordinatorDidRequestFullCaptureFallback(self)

        // Logout is best effort. Local credentials have already been cleared.
        logout?.observe { _ in }

        // #TODO - Networked Identity: After document/selfie capture, offer Link login and explicit save opt-in. The new API must record consent and the Link account reference on the VerificationSession; the backend copies images asynchronously after verification succeeds. Its contract is still missing.
    }

    func requireReauthentication() {
        lastOTPError = .sessionExpired
        fallbackReason = nil
        emailAddress = nil
        redactedFormattedPhoneNumber = nil
        activeSMSVerificationSessionID = nil
        knownSMSVerificationSessionIDs = []
        credentialStore.clearConsumerCredentials()
        transition(to: .reauthenticationRequired)
    }

    func transition(to state: NetworkedIdentityState) {
        self.state = state
        delegate?.networkedIdentityCoordinator(self, didTransitionTo: state)
    }

    func smsVerificationSessionIDs(
        in consumerSession: NetworkedIdentityConsumerSession
    ) -> Set<String> {
        Set(
            consumerSession.verificationSessions.compactMap { verificationSession in
                guard verificationSession.type == .sms else {
                    return nil
                }
                return verificationSession.id
            }
        )
    }

    var flowHasEnded: Bool {
        state == .cancelled || state == .fullCaptureFallback
    }

    func logOutIfFlowEnded(
        _ result: Result<NetworkedIdentityConsumerSessionResponse, Error>,
        consumerPublishableKey: String,
        verificationSessionClientSecrets: [String]?
    ) {
        guard flowHasEnded, case .success(let response) = result else {
            return
        }
        Self.bestEffortLogOut(
            using: apiClient,
            consumerSessionClientSecret: response.consumerSession.clientSecret,
            consumerPublishableKey: consumerPublishableKey,
            verificationSessionClientSecrets: NetworkedIdentityCredentialStore.appending(
                response.authSessionClientSecret,
                to: verificationSessionClientSecrets
            )
        )
    }

    func bestEffortLogOut(
        consumerSessionClientSecret: String,
        consumerPublishableKey: String,
        verificationSessionClientSecrets: [String]?
    ) {
        Self.bestEffortLogOut(
            using: apiClient,
            consumerSessionClientSecret: consumerSessionClientSecret,
            consumerPublishableKey: consumerPublishableKey,
            verificationSessionClientSecrets: verificationSessionClientSecrets
        )
    }

    static func logOutSuccessfulResponse(
        _ result: Result<NetworkedIdentityConsumerSessionResponse, Error>,
        using apiClient: NetworkedIdentityAPIClient,
        consumerPublishableKey: String,
        verificationSessionClientSecrets: [String]?
    ) {
        guard case .success(let response) = result else {
            return
        }
        bestEffortLogOut(
            using: apiClient,
            consumerSessionClientSecret: response.consumerSession.clientSecret,
            consumerPublishableKey: consumerPublishableKey,
            verificationSessionClientSecrets: NetworkedIdentityCredentialStore.appending(
                response.authSessionClientSecret,
                to: verificationSessionClientSecrets
            )
        )
    }

    static func bestEffortLogOut(
        using apiClient: NetworkedIdentityAPIClient,
        consumerSessionClientSecret: String,
        consumerPublishableKey: String,
        verificationSessionClientSecrets: [String]?
    ) {
        apiClient.logOut(
            consumerSessionClientSecret: consumerSessionClientSecret,
            verificationSessionClientSecrets: verificationSessionClientSecrets,
            consumerPublishableKey: consumerPublishableKey
        ).observe { _ in }
    }
}
