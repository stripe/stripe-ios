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

@_spi(STP) public protocol PaymentSheetLinkAccountInfoProtocol {
    @_spi(STP) var email: String { get }
    @_spi(STP) var redactedPhoneNumber: String? { get }
    @_spi(STP) var isRegistered: Bool { get }
    @_spi(STP) var sessionState: PaymentSheetLinkAccount.SessionState { get }
    @_spi(STP) var consumerSessionClientSecret: String? { get }
}

struct LinkPMDisplayDetails {
    let last4: String
    let brand: STPCardBrand
}

@_spi(STP) public class PaymentSheetLinkAccount: PaymentSheetLinkAccountInfoProtocol {
    @_spi(STP) public enum SessionState: String {
        case requiresSignUp
        case requiresVerification
        case verified
    }

    // More information: go/link-signup-consent-action-log
    @_spi(STP) public enum ConsentAction: String {
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

        // Checkbox pre-checked, w/ email & phone prefilled
        case prechecked_opt_in_box_prefilled_all = "prechecked_opt_in_box_prefilled_all"

        // Checkbox pre-checked, some fields prefilled
        case prechecked_opt_in_box_prefilled_some = "prechecked_opt_in_box_prefilled_some"

        // Checkbox pre-checked, no fields prefilled
        case prechecked_opt_in_box_prefilled_none = "prechecked_opt_in_box_prefilled_none"

        // Crypto onramp, email and phone number are entered, a sign up button is tapped
        case entered_phone_number_email_clicked_signup_crypto_onramp = "entered_phone_number_email_clicked_signup_crypto_onramp"

        // Checkbox pre-checked, signup data inferred from billing details or customer information
        case sign_up_opt_in_mobile_prechecked = "sign_up_opt_in_mobile_prechecked"

        // Checkbox checked, signup data inferred from billing details or customer information
        case sign_up_opt_in_mobile_checked = "sign_up_opt_in_mobile_checked"
    }

    // Dependencies
    let apiClient: STPAPIClient

    let useMobileEndpoints: Bool
    let canSyncAttestationState: Bool
    let requestSurface: LinkRequestSurface
    let createdFromAuthIntentID: Bool

    /// Publishable key of the Consumer Account.
    private(set) var publishableKey: String?

    var paymentSheetLinkAccountDelegate: PaymentSheetLinkAccountDelegate?

    var phoneNumberUsedInSignup: String?
    var nameUsedInSignup: String?
    var suggestedEmail: String?

    @_spi(STP) public let email: String

    @_spi(STP) public var redactedPhoneNumber: String? {
        return currentSession?.redactedFormattedPhoneNumber.replacingOccurrences(of: "*", with: "•")
    }

    @_spi(STP) public var isRegistered: Bool {
        return currentSession != nil
    }

    @_spi(STP) public var sessionState: SessionState {
        if let currentSession = currentSession {
            // sms verification is not required if we are in the signup flow or are using seamless sign-in
            return currentSession.hasVerifiedSMSSession || currentSession.isVerifiedForSignup || currentSession.isVerifiedWithLinkAuthToken
                ? .verified : .requiresVerification
        } else {
            return .requiresSignUp
        }
    }

    @_spi(STP) public var consumerSessionClientSecret: String? {
        currentSession?.clientSecret
    }

    var hasStartedSMSVerification: Bool {
        return currentSession?.hasStartedSMSVerification ?? false
    }

    var hasCompletedSMSVerification: Bool {
        return currentSession?.hasVerifiedSMSSession ?? false
    }

    var isInSignupFlow: Bool {
        currentSession?.isVerifiedForSignup ?? false
    }

    // Webview fallback URLs have a lifespan of one attempt.
    // If a user opens one and dismisses it, it can't be used again,
    // So we'll fetch a new one in that case.
    var visitedFallbackURLs: [URL] = []

    private(set) var currentSession: ConsumerSession?
    let displayablePaymentDetails: ConsumerSession.DisplayablePaymentDetails?

    init(
        email: String,
        session: ConsumerSession?,
        publishableKey: String?,
        displayablePaymentDetails: ConsumerSession.DisplayablePaymentDetails?,
        apiClient: STPAPIClient = .shared,
        useMobileEndpoints: Bool,
        canSyncAttestationState: Bool,
        requestSurface: LinkRequestSurface = .default,
        createdFromAuthIntentID: Bool = false
    ) {
        self.email = email
        self.currentSession = session
        self.publishableKey = publishableKey
        self.displayablePaymentDetails = displayablePaymentDetails
        self.apiClient = apiClient
        self.useMobileEndpoints = useMobileEndpoints
        self.canSyncAttestationState = canSyncAttestationState
        self.requestSurface = requestSurface
        self.createdFromAuthIntentID = createdFromAuthIntentID
    }

    func signUp(
        with phoneNumber: PhoneNumber?,
        legalName: String?,
        countryCode: String?,
        consentAction: ConsentAction,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        signUp(
            with: phoneNumber?.string(as: .e164),
            legalName: legalName,
            countryCode: phoneNumber?.countryCode ?? countryCode,
            consentAction: consentAction,
            completion: completion
        )
    }

    func signUp(
        with phoneNumber: String?,
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
            canSyncAttestationState: canSyncAttestationState,
            with: apiClient,
            requestSurface: requestSurface
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

    func startVerification(
        isResendingSmsCode: Bool = false,
        completion: @escaping (Result<Bool, Error>) -> Void
    ) {
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
            isResendingSmsCode: isResendingSmsCode,
            with: apiClient,
            requestSurface: requestSurface
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

    func verify(
        with oneTimePasscode: String,
        consentGranted: Bool? = nil,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
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
            requestSurface: requestSurface,
            consentGranted: consentGranted
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
                requestSurface: self.requestSurface,
                completion: completionRetryingOnAuthErrors
            )
        }
    }

    func createPaymentDetails(
        with paymentMethodParams: STPPaymentMethodParams,
        isDefault: Bool,
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
                isDefault: isDefault,
                requestSurface: self.requestSurface,
                completion: completionRetryingOnAuthErrors
            )
        }
    }

    func createPaymentDetails(
        linkedAccountId: String,
        isDefault: Bool,
        clientAttributionMetadata: STPClientAttributionMetadata?,
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
                isDefault: isDefault,
                clientAttributionMetadata: clientAttributionMetadata,
                requestSurface: self.requestSurface,
                completion: completionRetryingOnAuthErrors
            )
        }
    }

    func listPaymentDetails(
        supportedTypes: [ConsumerPaymentDetails.DetailsType],
        shouldRetryOnAuthError: Bool = true
    ) async throws -> [ConsumerPaymentDetails] {
        return try await withCheckedThrowingContinuation { continuation in
            listPaymentDetails(
                supportedTypes: supportedTypes,
                shouldRetryOnAuthError: shouldRetryOnAuthError
            ) { result in
                switch result {
                case .success(let details):
                    continuation.resume(returning: details)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func listPaymentDetails(
        supportedTypes: [ConsumerPaymentDetails.DetailsType],
        shouldRetryOnAuthError: Bool = true,
        completion: @escaping (Result<[ConsumerPaymentDetails], Error>) -> Void
    ) {
        retryingOnAuthError(
            shouldRetry: shouldRetryOnAuthError,
            completion: completion
        ) { completionRetryingOnAuthErrors in
            guard let session = self.currentSession else {
                stpAssertionFailure()
                completion(.failure(PaymentSheetError.unknown(debugDescription: "Paying with Link without valid session")))
                return
            }

            session.listPaymentDetails(
                with: self.apiClient,
                supportedPaymentDetailsTypes: supportedTypes,
                requestSurface: self.requestSurface,
                completion: completionRetryingOnAuthErrors
            )
        }
    }

    func listShippingAddress(
        shouldRetryOnAuthError: Bool = true
    ) async throws -> ShippingAddressesResponse {
        return try await withCheckedThrowingContinuation { continuation in
            listShippingAddress(shouldRetryOnAuthError: shouldRetryOnAuthError) { result in
                switch result {
                case .success(let response):
                    continuation.resume(returning: response)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func listShippingAddress(
        shouldRetryOnAuthError: Bool = true,
        completion: @escaping (Result<ShippingAddressesResponse, Error>) -> Void
    ) {
        retryingOnAuthError(
            shouldRetry: shouldRetryOnAuthError,
            completion: completion
        ) { completionRetryingOnAuthErrors in
            guard let session = self.currentSession else {
                stpAssertionFailure()
                completion(.failure(PaymentSheetError.unknown(debugDescription: "Paying with Link without valid session")))
                return
            }

            session.listShippingAddress(with: self.apiClient, requestSurface: self.requestSurface, completion: completionRetryingOnAuthErrors)
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
                requestSurface: self.requestSurface,
                completion: completionRetryingOnAuthErrors
            )
        }
    }

    func updatePaymentDetails(
        id: String,
        updateParams: UpdatePaymentDetailsParams,
        clientAttributionMetadata: STPClientAttributionMetadata?,
        completion: @escaping (Result<ConsumerPaymentDetails, Error>) -> Void
    ) {
        retryingOnAuthError(completion: completion) { [apiClient] completionRetryingOnAuthErrors in
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
                clientAttributionMetadata: clientAttributionMetadata,
                requestSurface: self.requestSurface,
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
        clientAttributionMetadata: STPClientAttributionMetadata?,
        completion: @escaping (Result<PaymentDetailsShareResponse, Error>
    ) -> Void) {
        retryingOnAuthError(completion: completion) { [apiClient] completionRetryingOnAuthErrors in
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
                clientAttributionMetadata: clientAttributionMetadata,
                requestSurface: self.requestSurface,
                completion: completionRetryingOnAuthErrors
            )
        }
    }

    func refresh(
        completion: @escaping (Result<ConsumerSession, Error>) -> Void
    ) {
        guard let session = currentSession else {
            stpAssertionFailure()
            completion(.failure(
                PaymentSheetError.unknown(debugDescription: "Refreshing session without valid current session")
            ))
            return
        }

        session.refreshSession(
            with: apiClient,
            requestSurface: requestSurface
        ) { [weak self] result in
            if case .success(let refreshedSession) = result {
                self?.currentSession = refreshedSession
            }
            completion(result)
        }
    }

    func logout() {
        guard let session = currentSession else {
            return
        }
        session.logout(with: apiClient, requestSurface: requestSurface) { _ in
            // We don't need to do anything if this fails, the key will expire automatically.
        }
    }
}

// MARK: - Equatable

extension PaymentSheetLinkAccount: Equatable {

    @_spi(STP) public static func == (lhs: PaymentSheetLinkAccount, rhs: PaymentSheetLinkAccount) -> Bool {
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
        shouldRetry: Bool = true,
        completion: @escaping CompletionBlock<T>,
        apiCall: @escaping (@escaping CompletionBlock<T>) -> Void
    ) {
        apiCall { [weak self] result in
            switch result {
            case .success:
                completion(result)
            case .failure(let error as NSError):
                if error.isLinkAuthError && shouldRetry && self?.createdFromAuthIntentID != true {
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
        billingPhoneNumber: String?,
        allowRedisplay: STPPaymentMethodAllowRedisplay?
    ) -> STPPaymentMethodParams? {
        guard let currentSession = currentSession else {
            stpAssertionFailure("Cannot make payment method params without an active session.")
            return nil
        }

        let params = STPPaymentMethodParams(type: .link)
        if let allowRedisplay {
            params.allowRedisplay = allowRedisplay
        }
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
        case bankAccount(
            billingDetails: STPPaymentMethodBillingDetails
        )
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
