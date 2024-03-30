//
//  PaymentSheetLinkAccount.swift
//  StripePaymentSheet
//
//  Created by Cameron Sabol on 7/8/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
@_spi(STP) import StripeUICore
import UIKit

protocol PaymentSheetLinkAccountInfoProtocol {
    var email: String { get }
    var isRegistered: Bool { get }
}

struct LinkPMDisplayDetails {
    let last4: String
    let brand: STPCardBrand
}

class PaymentSheetLinkAccount: PaymentSheetLinkAccountInfoProtocol {
    enum SessionState: String {
        case requiresSignUp
        case requiresVerification
        case verified
    }

    // More information: go/link-signup-consent-action-log
    enum ConsentAction: String {
        // Checkbox, no fields prefilled
        case checkbox_v0 = "clicked_checkbox_nospm_mobile_v0"

        // Checkbox, w/ email prefilled
        case checkbox_v0_0 = "clicked_checkbox_nospm_mobile_v0_0"

        // Checkbox, w/ email & phone prefilled
        case checkbox_v0_1 = "clicked_checkbox_nospm_mobile_v0_1"

        // Inline, no fields prefilled
        case implied_v0 = "implied_consent_withspm_mobile_v0"

        // Inline, email-prefilled
        case implied_v0_0 = "implied_consent_withspm_mobile_v0_0"

    }

    // Dependencies
    let apiClient: STPAPIClient

    /// Publishable key of the Consumer Account.
    private(set) var publishableKey: String?

    let email: String

    var isRegistered: Bool {
        return currentSession != nil
    }

    var isLoggedIn: Bool {
        return sessionState == .verified
    }

    var sessionState: SessionState {
        if let currentSession = currentSession {
            // sms verification is not required if we are in the signup flow
            return currentSession.hasVerifiedSMSSession || currentSession.isVerifiedForSignup
                ? .verified : .requiresVerification
        } else {
            return .requiresSignUp
        }
    }

    var hasStartedSMSVerification: Bool {
        return currentSession?.hasStartedSMSVerification ?? false
    }

    private var currentSession: ConsumerSession?

    init(
        email: String,
        session: ConsumerSession?,
        publishableKey: String?,
        apiClient: STPAPIClient = .shared
    ) {
        self.email = email
        self.currentSession = session
        self.publishableKey = publishableKey
        self.apiClient = apiClient
    }

    func signUp(
        with phoneNumber: PhoneNumber,
        legalName: String?,
        consentAction: ConsentAction,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        signUp(
            with: phoneNumber.string(as: .e164),
            legalName: legalName,
            countryCode: phoneNumber.countryCode,
            consentAction: consentAction,
            completion: completion
        )
    }

    func signUp(
        with phoneNumber: String,
        legalName: String?,
        countryCode: String?,
        consentAction: ConsentAction,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        guard case .requiresSignUp = sessionState else {
            STPAnalyticsClient.sharedClient.logLinkInvalidSessionState(sessionState: sessionState)
            DispatchQueue.main.async {
                completion(
                    .failure(
                        PaymentSheetError.linkSignUpNotRequired
                    )
                )
            }
            return
        }

        ConsumerSession.signUp(
            email: email,
            phoneNumber: phoneNumber,
            legalName: legalName,
            countryCode: countryCode,
            consentAction: consentAction.rawValue,
            with: apiClient
        ) { [weak self] result in
            switch result {
            case .success(let signupResponse):
                self?.currentSession = signupResponse.consumerSession
                self?.publishableKey = signupResponse.publishableKey
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func createPaymentDetails(
        with paymentMethodParams: STPPaymentMethodParams,
        completion: @escaping (Result<ConsumerPaymentDetails, Error>) -> Void
    ) {
        guard let session = currentSession else {
            assertionFailure()
            completion(
                .failure(PaymentSheetError.savingWithoutValidLinkSession)
            )
            return
        }

        retryingOnAuthError(completion: completion) { [apiClient, publishableKey] completionWrapper in
            session.createPaymentDetails(
                paymentMethodParams: paymentMethodParams,
                with: apiClient,
                consumerAccountPublishableKey: publishableKey,
                completion: completionWrapper
            )
        }
    }

    func sharePaymentDetails(id: String, cvc: String?, completion: @escaping (Result<PaymentDetailsShareResponse, Error>) -> Void) {
        guard let session = currentSession else {
            assertionFailure()
            return completion(
                .failure(
                    PaymentSheetError.savingWithoutValidLinkSession
                )
            )
        }

        retryingOnAuthError(completion: completion) { [apiClient, publishableKey] completionWrapper in
            session.sharePaymentDetails(
                with: apiClient,
                id: id,
                cvc: cvc,
                consumerAccountPublishableKey: publishableKey,
                completion: completionWrapper
            )
        }
    }

    func logout() {
        guard let session = currentSession else {
            return
        }
        session.logout(with: apiClient, consumerAccountPublishableKey: publishableKey) { _ in
            // We don't need to do anything if this fails, the key will expire automatically.
        }
    }
}

// MARK: - Equatable

extension PaymentSheetLinkAccount: Equatable {

    static func == (lhs: PaymentSheetLinkAccount, rhs: PaymentSheetLinkAccount) -> Bool {
        return
            (lhs.email == rhs.email && lhs.currentSession == rhs.currentSession
            && lhs.publishableKey == rhs.publishableKey)
    }

}

// MARK: - Session refresh

private extension PaymentSheetLinkAccount {

    typealias CompletionBlock<T> = (Result<T, Error>) -> Void

    func retryingOnAuthError<T>(
        completion: @escaping CompletionBlock<T>,
        apiCall: @escaping (@escaping CompletionBlock<T>) -> Void
    ) {
        apiCall { [weak self] result in
            switch result {
            case .success:
                completion(result)
            case .failure(let error as NSError):
                let isAuthError =
                    (error.domain == STPError.stripeDomain && error.code == STPErrorCode.authenticationError.rawValue)

                if isAuthError {
                    self?.refreshSession { refreshSessionResult in
                        switch refreshSessionResult {
                        case .success:
                            apiCall(completion)
                        case .failure:
                            completion(result)
                        }
                    }
                } else {
                    completion(result)
                }
            }
        }
    }

    func refreshSession(
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        // The consumer session lookup endpoint currently serves as our endpoint for
        // refreshing the session. To refresh the session, we need to call this endpoint
        // without providing an email address.
        ConsumerSession.lookupSession(
            for: nil,  // No email address
            with: apiClient
        ) { [weak self] result in
            switch result {
            case .success(let response):
                switch response.responseType {
                case .found(let session):
                    self?.currentSession = session.consumerSession
                    self?.publishableKey = session.publishableKey
                    completion(.success(()))
                case .notFound(let message):
                    completion(
                        .failure(PaymentSheetError.linkLookupNotFound(serverErrorMessage: message))
                    )
                case .noAvailableLookupParams:
                    completion(
                        .failure(PaymentSheetError.missingClientSecret)
                    )
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

}

// MARK: - Payment method params

extension PaymentSheetLinkAccount {

    /// Converts a `ConsumerPaymentDetails` into a `STPPaymentMethodParams` object, injecting
    /// the required Link credentials.
    ///
    /// Returns `nil` if not authenticated/logged in.
    ///
    /// - Parameter paymentDetails: Payment details
    /// - Returns: Payment method params for paying with Link.
    func makePaymentMethodParams(from paymentDetails: ConsumerPaymentDetails, cvc: String?) -> STPPaymentMethodParams? {
        guard let currentSession = currentSession else {
            assertionFailure("Cannot make payment method params without an active session.")
            return nil
        }

        let params = STPPaymentMethodParams(type: .link)
        params.link?.paymentDetailsID = paymentDetails.stripeID
        params.link?.credentials = ["consumer_session_client_secret": currentSession.clientSecret]

        if let cvc = cvc {
            params.link?.additionalAPIParameters["card"] = [
                "cvc": cvc,
            ]
        }

        return params
    }
}
