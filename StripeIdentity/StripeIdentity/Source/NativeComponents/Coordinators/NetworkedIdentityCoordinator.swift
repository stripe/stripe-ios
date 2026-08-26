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
    private let credentialStore: NetworkedIdentityCredentialStore
    private let currentTime: () -> TimeInterval
    private var emailAddress: String?
    private var activeSMSVerificationSessionID: String?
    private var knownSMSVerificationSessionIDs: Set<String> = []

    weak var delegate: NetworkedIdentityCoordinatorDelegate?

    private(set) var state: NetworkedIdentityState = .collectEmail
    private(set) var lastOTPError: NetworkedIdentityOTPError?
    private(set) var fallbackReason: NetworkedIdentityFallbackReason?
    private(set) var availableDocuments: [NetworkedIdentityDocument] = []
    private(set) var selectedDocument: NetworkedIdentityDocument?

    init(
        apiClient: NetworkedIdentityAPIClient,
        verificationSessionClientSecrets: [String]? = nil,
        credentialStore: NetworkedIdentityCredentialStore? = nil,
        currentTime: @escaping () -> TimeInterval = { Date().timeIntervalSince1970 }
    ) {
        self.apiClient = apiClient
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
        confirmation.observe(on: .main) { [weak self] result in
            guard let self else {
                return
            }
            guard self.state == .otpConfirmPending else {
                self.logOutIfCancelled(
                    result,
                    consumerPublishableKey: request.1,
                    verificationSessionClientSecrets: request.0.verificationSessionClientSecrets
                )
                return
            }

            switch result {
            case .success(let response):
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

    func selectDocument(_ document: NetworkedIdentityDocument) {
        guard state == .selectDocument,
              let selectedDocument = availableDocuments.first(where: { $0.id == document.id }) else {
            return
        }

        self.selectedDocument = selectedDocument
        transition(to: .selectedDocument)

        // #TODO - Networked Identity: Plumb recipient and requested-attribute metadata, present the documented explicit reuse consent, and define cloneConsumerIdentityDocument before requesting an association token or completing the flow.
    }

    func cancel() {
        guard state != .cancelled else {
            return
        }

        let logout = credentialStore.readConsumerCredentials { credentials, verificationSessionClientSecrets in
            apiClient.logOut(
                consumerSessionClientSecret: credentials.sessionClientSecret,
                verificationSessionClientSecrets: verificationSessionClientSecrets,
                consumerPublishableKey: credentials.publishableKey
            )
        }

        credentialStore.clear()
        emailAddress = nil
        activeSMSVerificationSessionID = nil
        knownSMSVerificationSessionIDs = []
        lastOTPError = nil
        fallbackReason = nil
        availableDocuments = []
        selectedDocument = nil
        transition(to: .cancelled)

        // Logout is best effort. Local credentials have already been cleared.
        logout?.observe { _ in }
    }
}

// MARK: - Private

private extension NetworkedIdentityCoordinator {
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
        lookup.observe(on: .main) { [weak self] result in
            guard let self else {
                return
            }
            guard self.state == .lookupPending else {
                if self.state == .cancelled,
                   case .success(.found(let response)) = result {
                    self.bestEffortLogOut(
                        consumerSessionClientSecret: response.consumerSession.clientSecret,
                        consumerPublishableKey: response.publishableKey,
                        verificationSessionClientSecrets: verificationSessionClientSecrets
                    )
                }
                return
            }

            switch result {
            case .success(.found(let response)):
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

    func beginFreshSMSVerification() {
        activeSMSVerificationSessionID = nil
        let knownSMSVerificationSessionIDs = knownSMSVerificationSessionIDs
        guard let request = credentialStore.readConsumerCredentials({ credentials, verificationSessionClientSecrets in
            return (
                NetworkedIdentityStartVerificationRequest(
                    consumerSessionClientSecret: credentials.sessionClientSecret,
                    type: .sms,
                    locale: nil,
                    accountPhoneNumber: nil,
                    verificationSessionClientSecrets: verificationSessionClientSecrets
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
        startVerification.observe(on: .main) { [weak self] result in
            guard let self else {
                return
            }
            guard self.state == .otpStartPending else {
                self.logOutIfCancelled(
                    result,
                    consumerPublishableKey: request.1,
                    verificationSessionClientSecrets: request.0.verificationSessionClientSecrets
                )
                return
            }

            switch result {
            case .success(let response):
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
                self.knownSMSVerificationSessionIDs.formUnion(
                    self.smsVerificationSessionIDs(in: response.consumerSession)
                )
                guard startedSMSSessions.count == 1,
                      let verificationSessionID = startedSMSSessions[0].id,
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
                    document.documentType != .unparsable
                        && document.expirationDate.map { TimeInterval($0) > now } != false
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
        let logout = credentialStore.readConsumerCredentials { credentials, verificationSessionClientSecrets in
            apiClient.logOut(
                consumerSessionClientSecret: credentials.sessionClientSecret,
                verificationSessionClientSecrets: verificationSessionClientSecrets,
                consumerPublishableKey: credentials.publishableKey
            )
        }

        credentialStore.clear()
        emailAddress = nil
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

        // #TODO - Networked Identity: Offering save-to-Link after manual capture is blocked on the missing write-back API contract.
        // #TODO - Networked Identity: Define session extension/rotation before retaining, rather than logging out, an authenticated Link session through manual capture for Save ID.
    }

    func requireReauthentication() {
        lastOTPError = .sessionExpired
        fallbackReason = nil
        emailAddress = nil
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

    func logOutIfCancelled(
        _ result: Result<NetworkedIdentityConsumerSessionResponse, Error>,
        consumerPublishableKey: String,
        verificationSessionClientSecrets: [String]?
    ) {
        guard state == .cancelled, case .success(let response) = result else {
            return
        }
        bestEffortLogOut(
            consumerSessionClientSecret: response.consumerSession.clientSecret,
            consumerPublishableKey: consumerPublishableKey,
            verificationSessionClientSecrets: verificationSessionClientSecrets
        )
    }

    func bestEffortLogOut(
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
