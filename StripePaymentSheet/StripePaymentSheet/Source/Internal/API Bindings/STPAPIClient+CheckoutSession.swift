//
//  STPAPIClient+CheckoutSession.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 1/15/26.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments

extension STPAPIClient {

    /// Initializes a CheckoutSession, fetching payment configuration data.
    /// - Parameters:
    ///   - checkoutSessionId: The ID of the checkout session (e.g., "cs_test_xxx")
    ///   - adaptivePricingAllowed: Whether the integration allows adaptive pricing for this session.
    /// - Returns: STPCheckoutSession object representing the checkout session.
    func initCheckoutSession(
        checkoutSessionId: String,
        adaptivePricingAllowed: Bool
    ) async throws -> STPCheckoutSession {
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

        let checkoutSession: STPCheckoutSession = try await APIRequest<STPCheckoutSession>.post(
            with: self,
            endpoint: "payment_pages/\(checkoutSessionId)/init",
            parameters: parameters
        )

        return checkoutSession
    }

    /// Updates a CheckoutSession with the provided parameters.
    /// - Parameters:
    ///   - checkoutSessionId: The ID of the checkout session (e.g., "cs_test_xxx")
    ///   - parameters: The update parameters (e.g., promotion_code)
    /// - Returns: The updated STPCheckoutSession
    func updateCheckoutSession(
        checkoutSessionId: String,
        parameters: [String: Any]
    ) async throws -> STPCheckoutSession {
        var params = parameters
        params["elements_session_client"] = [
            "is_aggregation_expected": true,
        ]
        return try await APIRequest<STPCheckoutSession>.post(
            with: self,
            endpoint: "payment_pages/\(checkoutSessionId)",
            parameters: params
        )
    }

    func detachPaymentMethod(
        _ paymentMethodId: String,
        fromCheckoutSession checkoutSessionId: String
    ) async throws {
        _ = try await APIRequest<STPCheckoutSession>.post(
            with: self,
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
    /// - Returns: The updated STPCheckoutSession.
    func updatePaymentMethod(
        _ paymentMethodId: String,
        inCheckoutSession checkoutSessionId: String,
        billingDetails: Checkout.PaymentMethodBillingDetails? = nil,
        expiryDetails: Checkout.PaymentMethodExpiryDetails? = nil
    ) async throws -> STPCheckoutSession {
        var params = Self.updatePaymentMethodParameters(
            paymentMethodId: paymentMethodId,
            billingDetails: billingDetails,
            expiryDetails: expiryDetails
        )
        params["elements_session_client"] = ["is_aggregation_expected": true]
        return try await APIRequest<STPCheckoutSession>.post(
            with: self,
            endpoint: "payment_pages/\(checkoutSessionId)",
            parameters: params
        )
    }

    static func updatePaymentMethodParameters(
        paymentMethodId: String,
        billingDetails: Checkout.PaymentMethodBillingDetails?,
        expiryDetails: Checkout.PaymentMethodExpiryDetails?
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

    /// Confirms a CheckoutSession with the provided payment method and parameters.
    /// - Parameters:
    ///   - sessionId: The ID of the checkout session (e.g., "cs_test_xxx")
    ///   - paymentMethod: The ID of the payment method to use for confirmation (payment method must have billing email)
    ///   - expectedAmount: The expected amount for validation. `nil` in setup mode.
    ///   - expectedPaymentMethodType: The expected payment method type (e.g., "card")
    ///   - savePaymentMethod: Optional top-level save_payment_method value that controls whether confirmation attaches the payment method to the Checkout Session's customer.
    ///   - returnURL: Optional return URL for redirect-based payment methods
    ///   - shipping: Optional shipping details
    ///   - paymentMethodOptions: Optional payment method options. BLIK code is extracted and passed as top-level `blik_code` parameter.
    ///   - clientAttributionMetadata: Optional client attribution metadata for analytics
    ///   - passiveCaptchaToken: Optional hCaptcha challenge response token
    /// - Returns: STPCheckoutSession containing the full confirmed session with expanded intents
    func confirmCheckoutSession(
        sessionId: String,
        paymentMethod: String,
        expectedAmount: Int?,
        expectedPaymentMethodType: String,
        savePaymentMethod: Bool? = nil,
        returnURL: String? = nil,
        shipping: STPPaymentIntentShippingDetailsParams? = nil,
        paymentMethodOptions: STPConfirmPaymentMethodOptions? = nil,
        clientAttributionMetadata: STPClientAttributionMetadata? = nil,
        passiveCaptchaToken: String? = nil
    ) async throws -> STPCheckoutSession {
        var parameters: [String: Any] = [
            "payment_method": paymentMethod,
            "expected_payment_method_type": expectedPaymentMethodType,
            "elements_session_client": ["is_aggregation_expected": true],
            "expand": [
                "payment_intent",
                "payment_intent.payment_method",
                "setup_intent",
                "setup_intent.payment_method",
            ],
        ]

        if let expectedAmount {
            parameters["expected_amount"] = expectedAmount
        }

        if let savePaymentMethod {
            parameters["save_payment_method"] = savePaymentMethod
        }

        if let returnURL {
            parameters["return_url"] = returnURL
        }

        if let shipping {
            parameters["shipping"] = STPFormEncoder.dictionary(forObject: shipping)
        }

        // Checkout session confirm API uses top-level parameters for payment method specific options
        if let blikCode = paymentMethodOptions?.blikOptions?.code {
            parameters["blik_code"] = blikCode
        }

        if let clientAttributionMetadata {
            parameters["client_attribution_metadata"] = try clientAttributionMetadata.encodeJSONDictionary()
        }

        if let passiveCaptchaToken {
            parameters["passive_captcha_token"] = passiveCaptchaToken
        }

        return try await APIRequest<STPCheckoutSession>.post(
            with: self,
            endpoint: "payment_pages/\(sessionId)/confirm",
            parameters: parameters
        )
    }
}
