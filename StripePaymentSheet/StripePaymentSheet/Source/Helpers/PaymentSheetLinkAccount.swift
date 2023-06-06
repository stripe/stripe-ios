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
    var redactedPhoneNumber: String? { get }
    var isRegistered: Bool { get }
    var isLoggedIn: Bool { get }
}

class PaymentSheetLinkAccount: PaymentSheetLinkAccountInfoProtocol {
    enum SessionState {
        case requiresSignUp
        case requiresVerification
        case verified
    }

    enum ConsentAction: String {
        case checkbox = "clicked_checkbox_mobile"
        case button = "clicked_button_mobile"
    }

    // Dependencies
    let apiClient: STPAPIClient

    /// Publishable key of the Consumer Account.
    private(set) var publishableKey: String?

    let email: String

    var redactedPhoneNumber: String? {
        return currentSession?.redactedPhoneNumber
    }

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
            assertionFailure()
            DispatchQueue.main.async {
                completion(
                    .failure(
                        PaymentSheetError.unknown(debugDescription: "Don't call sign up if not needed")
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
            case .success(let session):
                self?.currentSession = session.consumerSession
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
                .failure(PaymentSheetError.unknown(debugDescription: "Saving to Link without valid session"))
            )
            return
        }

        session.createPaymentDetails(
            paymentMethodParams: paymentMethodParams,
            with: apiClient,
            consumerAccountPublishableKey: publishableKey,
            completion: completion
        )
    }

    func logout(completion: (() -> Void)? = nil) {
        guard let session = currentSession else {
            assertionFailure("Cannot logout without an active session")
            completion?()
            return
        }

        session.logout(
            with: apiClient,
            consumerAccountPublishableKey: publishableKey
        ) { _ in
            completion?()
        }

        markEmailAsLoggedOut()

        // Forget current session.
        self.currentSession = nil
    }

    func markEmailAsLoggedOut() {
        /*guard let hashedEmail = email.lowercased().sha256 else {
            return
        }*/

        //cookieStore.write(key: .lastLogoutEmail, value: hashedEmail)
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
    func makePaymentMethodParams(from paymentDetails: ConsumerPaymentDetails) -> STPPaymentMethodParams? {
        guard let currentSession = currentSession else {
            assertionFailure("Cannot make payment method params without an active session.")
            return nil
        }

        let params = STPPaymentMethodParams(type: .link)
        params.link?.paymentDetailsID = paymentDetails.stripeID
        params.link?.credentials = ["consumer_session_client_secret": currentSession.clientSecret]

        if let cvc = paymentDetails.cvc {
            params.link?.additionalAPIParameters["card"] = [
                "cvc": cvc,
            ]
        }

        return params
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

// MARK: - Payment method availability

extension PaymentSheetLinkAccount {

    /// Returns a set containing the Payment Details types that the user is able to use for confirming the given `intent`.
    /// - Parameter intent: The Intent that the user is trying to confirm.
    /// - Returns: A set containing the supported Payment Details types.
    func supportedPaymentDetailsTypes(for intent: Intent) -> Set<ConsumerPaymentDetails.DetailsType> {
        guard let currentSession = currentSession, let fundingSources = intent.linkFundingSources else {
            return []
        }

        let fundingSourceDetailsTypes = Set(fundingSources.compactMap { $0.detailsType })

        // Take the intersection of the consumer session types and the merchant-provided Link funding sources
        var supportedPaymentDetailsTypes = fundingSourceDetailsTypes.intersection(currentSession.supportedPaymentDetailsTypes)

        // Special testmode handling
        if apiClient.isTestmode && Self.emailSupportsMultipleFundingSourcesOnTestMode(email) {
            supportedPaymentDetailsTypes.insert(.bankAccount)
        }

        return supportedPaymentDetailsTypes
    }

    func supportedPaymentMethodTypes(for intent: Intent) -> [STPPaymentMethodType] {
        var supportedPaymentMethodTypes = [STPPaymentMethodType]()

        for paymentDetailsType in supportedPaymentDetailsTypes(for: intent) {
            switch paymentDetailsType {
            case .card:
                supportedPaymentMethodTypes.append(.card)
            case .bankAccount:
                supportedPaymentMethodTypes.append(.linkInstantDebit)
            case .unparsable:
                break
            }
        }

        if supportedPaymentMethodTypes.isEmpty {
            // Card is the default payment method type when no other type is available.
            supportedPaymentMethodTypes.append(.card)
        }

        return supportedPaymentMethodTypes
    }
}

// MARK: - Helpers

private extension PaymentSheetLinkAccount {

    /// On *testmode* we use special email addresses for testing multiple funding sources. This method returns `true`
    /// if the given `email` is one of such email addresses.
    ///
    /// - Parameter email: Email.
    /// - Returns: Whether or not should enable multiple funding sources on test mode.
    static func emailSupportsMultipleFundingSourcesOnTestMode(_ email: String) -> Bool {
        return email.contains("+multiple_funding_sources@")
    }

}

private extension LinkSettings.FundingSource {
    var detailsType: ConsumerPaymentDetails.DetailsType? {
        switch self {
        case .card:
            return .card
        case .bankAccount:
            return .bankAccount
        }
    }
}
