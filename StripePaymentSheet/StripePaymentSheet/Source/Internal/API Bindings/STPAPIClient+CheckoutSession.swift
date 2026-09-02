//
//  STPAPIClient+CheckoutSession.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 1/15/26.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments

/// The parameters sent to the Checkout Session `/confirm` endpoint.
struct CheckoutSessionConfirmationRequestParameters {
    /// The ID of the Checkout Session (e.g., `cs_test_xxx`).
    let sessionId: String

    /// The ID of the PaymentMethod to use for confirmation. The PaymentMethod must have a billing email.
    let paymentMethodId: String

    /// The expected amount for validation. `nil` for setup-style Sessions.
    let expectedAmount: Int?

    /// The expected PaymentMethod type (e.g., `card`).
    let expectedPaymentMethodType: String

    /// The optional top-level `save_payment_method` value that controls whether confirmation
    /// attaches the PaymentMethod to the Checkout Session's customer.
    let savePaymentMethod: Bool?

    /// The optional return URL for redirect-based payment methods.
    let returnURL: String?

    /// The optional shipping details.
    let shipping: STPPaymentIntentShippingDetailsParams?

    /// The optional PaymentMethod options. The BLIK code is extracted and passed as the
    /// top-level `blik_code` parameter.
    let paymentMethodOptions: STPConfirmPaymentMethodOptions?

    /// The optional client attribution metadata for analytics.
    let clientAttributionMetadata: STPClientAttributionMetadata?

    /// The optional hCaptcha challenge response token.
    let passiveCaptchaToken: String?

    init(
        sessionId: String,
        paymentMethodId: String,
        expectedAmount: Int?,
        expectedPaymentMethodType: String,
        savePaymentMethod: Bool? = nil,
        returnURL: String? = nil,
        shipping: STPPaymentIntentShippingDetailsParams? = nil,
        paymentMethodOptions: STPConfirmPaymentMethodOptions? = nil,
        clientAttributionMetadata: STPClientAttributionMetadata? = nil,
        passiveCaptchaToken: String? = nil
    ) {
        self.sessionId = sessionId
        self.paymentMethodId = paymentMethodId
        self.expectedAmount = expectedAmount
        self.expectedPaymentMethodType = expectedPaymentMethodType
        self.savePaymentMethod = savePaymentMethod
        self.returnURL = returnURL
        self.shipping = shipping
        self.paymentMethodOptions = paymentMethodOptions
        self.clientAttributionMetadata = clientAttributionMetadata
        self.passiveCaptchaToken = passiveCaptchaToken
    }
}

extension CheckoutSessionConfirmationRequestParameters {
    init(
        checkoutSession: CheckoutController.Session,
        paymentMethod: STPPaymentMethod,
        configuration: PaymentElementConfiguration,
        paymentMethodOptions: STPConfirmPaymentMethodOptions?,
        savePaymentMethod: Bool?,
        clientAttributionMetadata: STPClientAttributionMetadata?
    ) {
        self.init(
            sessionId: checkoutSession.id,
            paymentMethodId: paymentMethod.stripeId,
            expectedAmount: checkoutSession.expectedAmount(),
            expectedPaymentMethodType: paymentMethod.type.identifier,
            savePaymentMethod: checkoutSession.noPaymentRequired ? nil : savePaymentMethod,
            returnURL: configuration.returnURL,
            shipping: STPPaymentIntentShippingDetailsParams(paymentSheetConfiguration: configuration),
            paymentMethodOptions: paymentMethodOptions,
            clientAttributionMetadata: clientAttributionMetadata
        )
    }
}

extension STPAPIClient {

    /// Initializes a CheckoutSession, fetching payment configuration data.
    /// - Parameters:
    ///   - checkoutSessionId: The ID of the checkout session (e.g., "cs_test_xxx")
    ///   - adaptivePricingAllowed: Whether the integration allows adaptive pricing for this session.
    /// - Returns: Internal Payment Pages API response for the checkout session.
    func initCheckoutSession(
        checkoutSessionId: String,
        adaptivePricingAllowed: Bool
    ) async throws -> PaymentPagesAPIResponse {
        var elementsSessionParameters: [String: Any] = [
            "is_aggregation_expected": true,
            "locale": Locale.current.toLanguageTag(),
        ]
        if let sessionId = AnalyticsHelper.shared.sessionID {
            elementsSessionParameters["mobile_session_id"] = sessionId
        }
        if let appId = Bundle.main.bundleIdentifier {
            elementsSessionParameters["mobile_app_id"] = appId
        }
        let parameters: [String: Any] = [
            "browser_locale": Locale.current.toLanguageTag(),
            "browser_timezone": TimeZone.current.identifier,
            "eid": UUID().uuidString,
            "redirect_type": "embedded",
            "elements_session_client": elementsSessionParameters,
            "adaptive_pricing": [
                "allowed": adaptivePricingAllowed,
            ],
        ]

        let checkoutSession = try await post(
            endpoint: "payment_pages/\(checkoutSessionId)/init",
            parameters: parameters
        )

        return checkoutSession
    }

    /// Updates a CheckoutSession with the provided parameters.
    /// - Parameters:
    ///   - checkoutSessionId: The ID of the checkout session (e.g., "cs_test_xxx")
    ///   - parameters: The update parameters (e.g., promotion_code)
    /// - Returns: The updated Payment Pages API response.
    func updateCheckoutSession(
        checkoutSessionId: String,
        parameters: [String: Any]
    ) async throws -> PaymentPagesAPIResponse {
        var params = parameters
        params["elements_session_client"] = [
            "is_aggregation_expected": true,
        ]
        return try await post(
            endpoint: "payment_pages/\(checkoutSessionId)",
            parameters: params
        )
    }

    /// Retrieves the latest full Checkout Session.
    func retrieveCheckoutSession(
        checkoutSessionId: String
    ) async throws -> PaymentPagesAPIResponse {
        return try await get(
            endpoint: "payment_pages/\(checkoutSessionId)",
            parameters: [
                "elements_session_client": [
                    "is_aggregation_expected": true,
                ],
            ]
        )
    }

    /// Retrieves the small state object used to determine whether a Checkout
    /// Session transition is still in progress.
    func pollCheckoutSession(
        checkoutSessionId: String,
        timeout: TimeInterval
    ) async throws -> PaymentPagePollResponse {
        return try await get(
            endpoint: "payment_pages/\(checkoutSessionId)/poll",
            parameters: [:],
            timeout: timeout,
            retriesEnabled: false
        )
    }

    func detachPaymentMethod(
        _ paymentMethodId: String,
        fromCheckoutSession checkoutSessionId: String
    ) async throws {
        _ = try await post(
            endpoint: "payment_pages/\(checkoutSessionId)",
            parameters: [
                "payment_method_to_detach": paymentMethodId,
                "elements_session_client": ["is_aggregation_expected": true],
            ]
        )
    }

    /// Updates a saved payment method's billing details and/or card expiry on a Checkout Session.
    /// - Parameters:
    ///   - paymentMethodId: The ID of the payment method to update (e.g., "pm_xxx").
    ///   - checkoutSessionId: The ID of the checkout session (e.g., "cs_test_xxx").
    ///   - billingDetails: Optional billing details to update (name, email, phone, address).
    ///   - expiryDetails: Optional card expiry to update (month and year).
    /// - Returns: The updated Payment Pages API response.
    func updatePaymentMethod(
        _ paymentMethodId: String,
        inCheckoutSession checkoutSessionId: String,
        billingDetails: CheckoutController.PaymentMethodBillingDetails? = nil,
        expiryDetails: CheckoutController.PaymentMethodExpiryDetails? = nil
    ) async throws -> PaymentPagesAPIResponse {
        var params = Self.updatePaymentMethodParameters(
            paymentMethodId: paymentMethodId,
            billingDetails: billingDetails,
            expiryDetails: expiryDetails
        )
        params["elements_session_client"] = ["is_aggregation_expected": true]
        return try await post(
            endpoint: "payment_pages/\(checkoutSessionId)",
            parameters: params
        )
    }

    static func updatePaymentMethodParameters(
        paymentMethodId: String,
        billingDetails: CheckoutController.PaymentMethodBillingDetails?,
        expiryDetails: CheckoutController.PaymentMethodExpiryDetails?
    ) -> [String: Any] {
        var params: [String: Any] = [
            "payment_method_to_update[payment_method_id]": paymentMethodId,
        ]
        if let billing = billingDetails {
            let billingPrefix = "payment_method_to_update[billing_details]"
            if let name = billing.name { params["\(billingPrefix)[name]"] = name }
            if let email = billing.email { params["\(billingPrefix)[email]"] = email }
            if let phone = billing.phone { params["\(billingPrefix)[phone]"] = phone }
            if let address = billing.address {
                let addressPrefix = "\(billingPrefix)[address]"
                if let line1 = address.line1 { params["\(addressPrefix)[line1]"] = line1 }
                if let line2 = address.line2 { params["\(addressPrefix)[line2]"] = line2 }
                if let city = address.city { params["\(addressPrefix)[city]"] = city }
                if let state = address.state { params["\(addressPrefix)[state]"] = state }
                if let postalCode = address.postalCode { params["\(addressPrefix)[postal_code]"] = postalCode }
                if let country = address.country { params["\(addressPrefix)[country]"] = country }
            }
        }
        if let expiry = expiryDetails {
            let expiryPrefix = "payment_method_to_update[expiry_details]"
            params["\(expiryPrefix)[exp_month]"] = expiry.expMonth
            params["\(expiryPrefix)[exp_year]"] = expiry.expYear
        }
        return params
    }

    /// Confirms a Checkout Session with the provided request parameters.
    /// - Returns: Payment Pages API response containing the full confirmed session with expanded intents.
    func confirmCheckoutSession(
        with requestParameters: CheckoutSessionConfirmationRequestParameters
    ) async throws -> PaymentPagesAPIResponse {
        var parameters: [String: Any] = [
            "payment_method": requestParameters.paymentMethodId,
            "expected_payment_method_type": requestParameters.expectedPaymentMethodType,
            "elements_session_client": ["is_aggregation_expected": true],
            "expand": [
                "payment_intent",
                "payment_intent.payment_method",
                "setup_intent",
                "setup_intent.payment_method",
            ],
        ]

        if let expectedAmount = requestParameters.expectedAmount {
            parameters["expected_amount"] = expectedAmount
        }

        if let savePaymentMethod = requestParameters.savePaymentMethod {
            parameters["save_payment_method"] = savePaymentMethod
        }

        if let returnURL = requestParameters.returnURL {
            parameters["return_url"] = returnURL
        }

        if let shipping = requestParameters.shipping {
            parameters["shipping"] = STPFormEncoder.dictionary(forObject: shipping)
        }

        // Checkout session confirm API uses top-level parameters for payment method specific options
        if let blikCode = requestParameters.paymentMethodOptions?.blikOptions?.code {
            parameters["blik_code"] = blikCode
        }

        if let clientAttributionMetadata = requestParameters.clientAttributionMetadata {
            parameters["client_attribution_metadata"] = try clientAttributionMetadata.encodeJSONDictionary()
        }

        if let passiveCaptchaToken = requestParameters.passiveCaptchaToken {
            parameters["passive_captcha_token"] = passiveCaptchaToken
        }

        return try await post(
            endpoint: "payment_pages/\(requestParameters.sessionId)/confirm",
            parameters: parameters
        )
    }

    private func post(
        endpoint: String,
        parameters: [String: Any]
    ) async throws -> PaymentPagesAPIResponse {
        do {
            return try await withCheckedThrowingContinuation { continuation in
                post(resource: endpoint, parameters: parameters) { result in
                    continuation.resume(with: result)
                }
            }
        } catch {
            if error is DecodingError {
                reportUnexpectedPaymentPagesParsingError(error, apiClient: self)
            }
            throw error
        }
    }

    private func get<T: Decodable>(
        endpoint: String,
        parameters: [String: Any],
        timeout: TimeInterval? = nil,
        retriesEnabled: Bool = true
    ) async throws -> T {
        do {
            return try await withCheckedThrowingContinuation { continuation in
                get(
                    resource: endpoint,
                    parameters: parameters,
                    timeout: timeout,
                    retriesEnabled: retriesEnabled
                ) { (result: Result<T, Error>) in
                    continuation.resume(with: result)
                }
            }
        } catch {
            if error is DecodingError {
                reportUnexpectedPaymentPagesParsingError(error, apiClient: self)
            }
            throw error
        }
    }
}

extension STPAPIClient: CheckoutSessionPollingAPIClient {}
