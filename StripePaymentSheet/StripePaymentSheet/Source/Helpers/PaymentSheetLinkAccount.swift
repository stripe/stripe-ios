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
    // The session ID associated with the current Elements Session
    let elementsSessionID: String

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

    var hasStartedSMSVerification: Bool {
        return currentSession?.hasStartedSMSVerification ?? false
    }

    var hasCompletedSMSVerification: Bool {
        return currentSession?.hasVerifiedSMSSession ?? false
    }

    private var currentSession: ConsumerSession?

    init(
        email: String,
        session: ConsumerSession?,
        publishableKey: String?,
        apiClient: STPAPIClient = .shared,
        cookieStore: LinkCookieStore = LinkSecureCookieStore.shared,
        useMobileEndpoints: Bool,
        elementsSessionID: String
    ) {
        self.email = email
        self.currentSession = session
        self.publishableKey = publishableKey
        self.apiClient = apiClient
        self.cookieStore = cookieStore
        self.useMobileEndpoints = useMobileEndpoints
        self.elementsSessionID = elementsSessionID
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
        guard let session = currentSession else {
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

        retryingOnAuthError(completion: completion) { [publishableKey] completionWrapper in
            session.createLinkAccountSession(
                consumerAccountPublishableKey: publishableKey,
                completion: completionWrapper
            )
        }
    }

    func createPaymentDetails(
        with paymentMethodParams: STPPaymentMethodParams,
        completion: @escaping (Result<ConsumerPaymentDetails, Error>) -> Void
    ) {
        guard let session = currentSession else {
            stpAssertionFailure()
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

    func createPaymentDetails(
        linkedAccountId: String,
        completion: @escaping (Result<ConsumerPaymentDetails, Error>) -> Void
    ) {
        guard let session = currentSession else {
            stpAssertionFailure()
            completion(.failure(PaymentSheetError.unknown(debugDescription: "Saving to Link without valid session")))
            return
        }
        retryingOnAuthError(completion: completion) { [publishableKey] completionWrapper in
            session.createPaymentDetails(
                linkedAccountId: linkedAccountId,
                consumerAccountPublishableKey: publishableKey,
                completion: completionWrapper
            )
        }
    }

    func listPaymentDetails(
        completion: @escaping (Result<[ConsumerPaymentDetails], Error>) -> Void
    ) {
        guard let session = currentSession else {
            stpAssertionFailure()
            completion(.failure(PaymentSheetError.unknown(debugDescription: "Paying with Link without valid session")))
            return
        }

        retryingOnAuthError(completion: completion) { [apiClient, publishableKey] completionWrapper in
            session.listPaymentDetails(
                with: apiClient,
                consumerAccountPublishableKey: publishableKey,
                completion: completionWrapper
            )
        }
    }

    func deletePaymentDetails(id: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let session = currentSession else {
            stpAssertionFailure()
            return completion(
                .failure(
                    PaymentSheetError.unknown(
                        debugDescription: "Deleting Link payment details without valid session"
                    )
                )
            )
        }

        retryingOnAuthError(completion: completion) { [apiClient, publishableKey] completionWrapper in
            session.deletePaymentDetails(
                with: apiClient,
                id: id,
                consumerAccountPublishableKey: publishableKey,
                completion: completionWrapper
            )
        }
    }

    func updatePaymentDetails(
        id: String,
        updateParams: UpdatePaymentDetailsParams,
        completion: @escaping (Result<ConsumerPaymentDetails, Error>) -> Void
    ) {
        guard let session = currentSession else {
            stpAssertionFailure()
            return completion(
                .failure(
                    PaymentSheetError.unknown(
                        debugDescription: "Updating Link payment details without valid session"
                    )
                )
            )
        }

        retryingOnAuthError(completion: completion) { [apiClient, publishableKey] completionWrapper in
            session.updatePaymentDetails(
                with: apiClient,
                id: id,
                updateParams: updateParams,
                consumerAccountPublishableKey: publishableKey,
                completion: completionWrapper
            )
        }
    }

    func sharePaymentDetails(id: String, cvc: String?, completion: @escaping (Result<PaymentDetailsShareResponse, Error>) -> Void) {
        guard let session = currentSession else {
            stpAssertionFailure()
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
            emailSource: nil, // No source
            sessionID: elementsSessionID,
            with: apiClient,
            useMobileEndpoints: useMobileEndpoints
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
            stpAssertionFailure("Cannot make payment method params without an active session.")
            return nil
        }

        let params = STPPaymentMethodParams(type: .link)
        params.billingDetails = STPPaymentMethodBillingDetails(billingAddress: paymentDetails.billingAddress, email: paymentDetails.billingEmailAddress)
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
        case card(expiryDate: CardExpiryDate, billingDetails: STPPaymentMethodBillingDetails? = nil)
        // updating bank not supported
    }

    let isDefault: Bool?
    let details: DetailsType?

    init(isDefault: Bool? = nil, details: DetailsType? = nil) {
        self.isDefault = isDefault
        self.details = details
    }
}
