//
//  WalletViewModel.swift
//  StripePaymentSheet
//
//  Created by Mat Schmid on 6/4/25.
//

import Observation
@_spi(STP) import StripePayments
@_spi(STP) import StripeUICore

@available(iOS 17.0, *) @Observable
class WalletViewModel {
    enum ViewModelError: Error {
        case consumerNotFound
        case consumerSessionOrPublishableKeyMissing
    }

    private let apiClient: STPAPIClient
    private let elementsSession: STPElementsSession

    var session: ConsumerSession?
    var consumerPublishableKey: String?
    var email: String?

    var textFieldController: OneTimeCodeTextFieldController = OneTimeCodeTextFieldController()
    var linkButtonMode: LinkExpressCheckout.Mode = .button {
        didSet {
            textFieldController.clearCode()
        }
    }

    var useMobileEndpoints: Bool {
        elementsSession.linkSettings?.useAttestationEndpoints ?? false
    }

    init(from flowController: PaymentSheet.FlowController) {
        self.apiClient = flowController.configuration.apiClient
        self.elementsSession = flowController.elementsSession
        self.email = flowController.configuration.defaultBillingDetails.email
    }

    // MARK: - API Methods

    @MainActor
    func lookup(email: String) async throws -> ConsumerSession.SessionWithPublishableKey {
        try await withCheckedThrowingContinuation { continuation in
            apiClient.lookupConsumerSession(
                for: email,
                emailSource: .prefilledEmail,
                sessionID: elementsSession.sessionID,
                cookieStore: LinkSecureCookieStore.shared,
                useMobileEndpoints: useMobileEndpoints,
                doNotLogConsumerFunnelEvent: false,
                completion: { result in
                    switch result {
                    case .success(let lookupResponse):
                        switch lookupResponse.responseType {
                        case .found(let session):
                            continuation.resume(returning: session)
                        default:
                            continuation.resume(throwing: ViewModelError.consumerNotFound)
                        }
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                }
            )
        }
    }

    @MainActor
    func startVerification() async throws -> ConsumerSession {
        guard let session, let consumerPublishableKey else {
            throw ViewModelError.consumerSessionOrPublishableKeyMissing
        }

        return try await withCheckedThrowingContinuation { continuation in
            session.startVerification(
                consumerAccountPublishableKey: consumerPublishableKey,
                completion: { result in
                    switch result {
                    case .success(let session):
                        continuation.resume(returning: session)
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                }
            )
        }
    }

    @MainActor
    func confirmVerification(code: String) async throws -> ConsumerSession {
        guard let session, let consumerPublishableKey else {
            throw ViewModelError.consumerSessionOrPublishableKeyMissing
        }

        return try await withCheckedThrowingContinuation { continuation in
            session.confirmSMSVerification(
                with: code,
                consumerAccountPublishableKey: consumerPublishableKey,
                completion: { result in
                    switch result {
                    case .success(let session):
                        continuation.resume(returning: session)
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                }
            )
        }
    }
}
