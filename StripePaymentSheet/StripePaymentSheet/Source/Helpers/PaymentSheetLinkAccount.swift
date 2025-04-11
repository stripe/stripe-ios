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

        // Clicked button in separate Link sheet
        case clicked_button_mobile_v1 = "clicked_button_mobile_v1"
    }

    // Dependencies
    let apiClient: STPAPIClient
    let cookieStore: LinkCookieStore

    let useMobileEndpoints: Bool

    /// Publishable key of the Consumer Account.
    private(set) var publishableKey: String?

    var paymentSheetLinkAccountDelegate: PaymentSheetLinkAccountDelegate?

    var phoneNumberUsedInSignup: String?
    var nameUsedInSignup: String?

    let email: String

    var redactedPhoneNumber: String? {
        return currentSession?.redactedFormattedPhoneNumber.replacingOccurrences(of: "*", with: "•")
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

    var hasStartedSMSVerification: Bool {
        return currentSession?.hasStartedSMSVerification ?? false
    }

    var hasCompletedSMSVerification: Bool {
        return currentSession?.hasVerifiedSMSSession ?? false
    }

    private(set) var currentSession: ConsumerSession?

    init(
        email: String,
        session: ConsumerSession?,
        publishableKey: String?,
        apiClient: STPAPIClient = .shared,
        cookieStore: LinkCookieStore = LinkSecureCookieStore.shared,
        useMobileEndpoints: Bool
    ) {
        self.email = email
        self.currentSession = session
        self.publishableKey = publishableKey
        self.apiClient = apiClient
        self.cookieStore = cookieStore
        self.useMobileEndpoints = useMobileEndpoints
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
            useMobileEndpoints: useMobileEndpoints,
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

    func startVerification(completion: @escaping (Result<Bool, Error>) -> Void) {
        guard case .requiresVerification = sessionState else {
            DispatchQueue.main.async {
                completion(.success(false))
            }
            return
        }

        guard let session = currentSession else {
            stpAssertionFailure()
            DispatchQueue.main.async {
                completion(
                    .failure(
                        PaymentSheetError.unknown(debugDescription: "Don't call verify if not needed")
                    )
                )
            }
            return
        }

        session.startVerification(
            with: apiClient,
            cookieStore: cookieStore,
            consumerAccountPublishableKey: publishableKey
        ) { [weak self] result in
            switch result {
            case .success(let newSession):
                self?.currentSession = newSession
                completion(.success(newSession.hasStartedSMSVerification))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func verify(with oneTimePasscode: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard case .requiresVerification = sessionState,
            hasStartedSMSVerification,
            let session = currentSession
        else {
            stpAssertionFailure()
            DispatchQueue.main.async {
                completion(
                    .failure(
                        PaymentSheetError.unknown(debugDescription: "Don't call verify if not needed")
                    )
                )
            }
            return
        }

        session.confirmSMSVerification(
            with: oneTimePasscode,
            with: apiClient,
            cookieStore: cookieStore,
            consumerAccountPublishableKey: publishableKey
        ) { [weak self] result in
            switch result {
            case .success(let verifiedSession):
                self?.currentSession = verifiedSession
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func createLinkAccountSession(
        completion: @escaping (Result<LinkAccountSession, Error>) -> Void
    ) {
        retryingOnAuthError(completion: completion) { completionRetryingOnAuthErrors in
            guard let session = self.currentSession else {
                stpAssertionFailure()
                completion(
                    .failure(
                        PaymentSheetError.unknown(
                            debugDescription: "Linking account session without valid consumer session"
                        )
                    )
                )
                return
            }

            session.createLinkAccountSession(
                consumerAccountPublishableKey: self.publishableKey,
                completion: completionRetryingOnAuthErrors
            )
        }
    }

    func createPaymentDetails(
        with paymentMethodParams: STPPaymentMethodParams,
        completion: @escaping (Result<ConsumerPaymentDetails, Error>) -> Void
    ) {
        retryingOnAuthError(completion: completion) { completionRetryingOnAuthErrors in
            guard let session = self.currentSession else {
                stpAssertionFailure()
                completion(
                    .failure(PaymentSheetError.savingWithoutValidLinkSession)
                )
                return
            }

            session.createPaymentDetails(
                paymentMethodParams: paymentMethodParams,
                with: self.apiClient,
                consumerAccountPublishableKey: self.publishableKey,
                completion: completionRetryingOnAuthErrors
            )
        }
    }

    func createPaymentDetails(
        linkedAccountId: String,
        completion: @escaping (Result<ConsumerPaymentDetails, Error>) -> Void
    ) {
        retryingOnAuthError(completion: completion) { completionRetryingOnAuthErrors in
            guard let session = self.currentSession else {
                stpAssertionFailure()
                completionRetryingOnAuthErrors(.failure(PaymentSheetError.unknown(debugDescription: "Saving to Link without valid session")))
                return
            }

            session.createPaymentDetails(
                linkedAccountId: linkedAccountId,
                consumerAccountPublishableKey: self.publishableKey,
                completion: completionRetryingOnAuthErrors
            )
        }
    }

    func listPaymentDetails(
        supportedTypes: [ConsumerPaymentDetails.DetailsType],
        completion: @escaping (Result<[ConsumerPaymentDetails], Error>) -> Void
    ) {
        retryingOnAuthError(completion: completion) { completionRetryingOnAuthErrors in
            guard let session = self.currentSession else {
                stpAssertionFailure()
                completion(.failure(PaymentSheetError.unknown(debugDescription: "Paying with Link without valid session")))
                return
            }

            session.listPaymentDetails(
                with: self.apiClient,
                supportedPaymentDetailsTypes: supportedTypes,
                consumerAccountPublishableKey: self.publishableKey,
                completion: completionRetryingOnAuthErrors
            )
        }
    }

    func deletePaymentDetails(id: String, completion: @escaping (Result<Void, Error>) -> Void) {
        retryingOnAuthError(completion: completion) { completionRetryingOnAuthErrors in
            guard let session = self.currentSession else {
                stpAssertionFailure()
                return completion(
                    .failure(
                        PaymentSheetError.unknown(
                            debugDescription: "Deleting Link payment details without valid session"
                        )
                    )
                )
            }

            session.deletePaymentDetails(
                with: self.apiClient,
                id: id,
                consumerAccountPublishableKey: self.publishableKey,
                completion: completionRetryingOnAuthErrors
            )
        }
    }

    func updatePaymentDetails(
        id: String,
        updateParams: UpdatePaymentDetailsParams,
        completion: @escaping (Result<ConsumerPaymentDetails, Error>) -> Void
    ) {
        retryingOnAuthError(completion: completion) { [apiClient, publishableKey] completionRetryingOnAuthErrors in
            guard let session = self.currentSession else {
                stpAssertionFailure()
                return completion(
                    .failure(
                        PaymentSheetError.unknown(
                            debugDescription: "Updating Link payment details without valid session"
                        )
                    )
                )
            }

            session.updatePaymentDetails(
                with: apiClient,
                id: id,
                updateParams: updateParams,
                consumerAccountPublishableKey: publishableKey,
                completion: completionRetryingOnAuthErrors
            )
        }
    }

    func sharePaymentDetails(
        id: String,
        cvc: String?,
        allowRedisplay: STPPaymentMethodAllowRedisplay?,
        expectedPaymentMethodType: String?,
        billingPhoneNumber: String?,
        completion: @escaping (Result<PaymentDetailsShareResponse, Error>
    ) -> Void) {
        retryingOnAuthError(completion: completion) { [apiClient, publishableKey] completionRetryingOnAuthErrors in
            guard let session = self.currentSession else {
                stpAssertionFailure()
                return completion(
                    .failure(
                        PaymentSheetError.savingWithoutValidLinkSession
                    )
                )
            }

            session.sharePaymentDetails(
                with: apiClient,
                id: id,
                cvc: cvc,
                allowRedisplay: allowRedisplay,
                expectedPaymentMethodType: expectedPaymentMethodType,
                billingPhoneNumber: billingPhoneNumber,
                consumerAccountPublishableKey: publishableKey,
                completion: completionRetryingOnAuthErrors
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

    func markEmailAsLoggedOut() {
        guard let hashedEmail = email.lowercased().sha256 else {
            stpAssertionFailure()
            return
        }

        cookieStore.write(key: .lastLogoutEmail, value: hashedEmail)
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

    /// Attempts attempts a request using apiCall. If the session
    /// is invalid, refresh it and re-attempt the apiCall.
    func retryingOnAuthError<T>(
        completion: @escaping CompletionBlock<T>,
        apiCall: @escaping (@escaping CompletionBlock<T>) -> Void
    ) {
        apiCall { [weak self] result in
            switch result {
            case .success:
                completion(result)
            case .failure(let error as NSError):
                let isAuthError: Bool = {
                    if let stripeError = error as? StripeError,
                    case let .apiError(stripeAPIError) = stripeError,
                       stripeAPIError.code == "consumer_session_credentials_invalid" {
                        return true
                    }
                    return false
                }()

                if isAuthError {
                    self?.refreshSession { refreshSessionResult in
                        switch refreshSessionResult {
                        case .success(let refreshedSession):
                            self?.currentSession = refreshedSession
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
        completion: @escaping (Result<ConsumerSession, Error>) -> Void
    ) {
        guard let paymentSheetLinkAccountDelegate else {
            stpAssertionFailure()
            completion(.failure(PaymentSheetError.unknown(debugDescription: "Attempting to refresh the Link token, but the paymentSheetLinkAccount delegate is nil")))
            return
        }
        paymentSheetLinkAccountDelegate.refreshLinkSession(completion: completion)
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
    /// - Parameter cvc: The CVC that we need to pass for some transactions
    /// - Parameter billingPhoneNumber: The billing phone number to add to the params. Passing it separately because it's not part of the payment details.
    /// - Returns: Payment method params for paying with Link.
    func makePaymentMethodParams(
        from paymentDetails: ConsumerPaymentDetails,
        cvc: String?,
        billingPhoneNumber: String?
    ) -> STPPaymentMethodParams? {
        guard let currentSession = currentSession else {
            stpAssertionFailure("Cannot make payment method params without an active session.")
            return nil
        }

        let params = STPPaymentMethodParams(type: .link)
        params.billingDetails = STPPaymentMethodBillingDetails(billingAddress: paymentDetails.billingAddress, email: paymentDetails.billingEmailAddress)
        params.billingDetails?.phone = billingPhoneNumber
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

// MARK: - Payment method availability

extension PaymentSheetLinkAccount {

    /// Returns a set containing the Payment Details types that the user is able to use for confirming the given `intent`.
    /// - Parameter intent: The Intent that the user is trying to confirm.
    /// - Returns: A set containing the supported Payment Details types.
    func supportedPaymentDetailsTypes(for elementsSession: STPElementsSession) -> Set<ConsumerPaymentDetails.DetailsType> {
        guard let currentSession, let fundingSources = elementsSession.linkFundingSources else {
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

    func supportedPaymentMethodTypes(for elementsSession: STPElementsSession) -> [STPPaymentMethodType] {
        var supportedPaymentMethodTypes = [STPPaymentMethodType]()

        for paymentDetailsType in supportedPaymentDetailsTypes(for: elementsSession) {
            switch paymentDetailsType {
            case .card:
                supportedPaymentMethodTypes.append(.card)
            case .bankAccount:
                break
//                TODO(link): Fix instant debits
//                supportedPaymentMethodTypes.append(.instantDebits)
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

// MARK: UpdatePaymentDetailsParams

struct UpdatePaymentDetailsParams {
    enum DetailsType {
        case card(
            expiryDate: CardExpiryDate? = nil,
            billingDetails: STPPaymentMethodBillingDetails? = nil,
            preferredNetwork: String? = nil
        )
        // updating bank not supported
    }

    let isDefault: Bool?
    let details: DetailsType?

    init(isDefault: Bool? = nil, details: DetailsType? = nil) {
        self.isDefault = isDefault
        self.details = details
    }
}

protocol PaymentSheetLinkAccountDelegate {
    func refreshLinkSession(completion: @escaping (Result<ConsumerSession, Error>) -> Void)
}
