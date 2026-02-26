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
    /// - Parameter checkoutSessionId: The ID of the checkout session (e.g., "cs_test_xxx")
    /// - Returns: CheckoutSessionInitResponse containing the session and elements session
    func initCheckoutSession(checkoutSessionId: String) async throws -> STPCheckoutSession {
        let parameters: [String: Any] = [
            "browser_locale": Locale.current.toLanguageTag(),
            "browser_timezone": TimeZone.current.identifier,
            "eid": UUID().uuidString,
            "redirect_type": "embedded",
            "elements_session_client": [
                "is_aggregation_expected": true,
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
        return try await APIRequest<STPCheckoutSession>.post(
            with: self,
            endpoint: "payment_pages/\(checkoutSessionId)",
            parameters: parameters
        )
    }

    /// Confirms a CheckoutSession with the provided payment method and parameters.
    /// - Parameters:
    ///   - sessionId: The ID of the checkout session (e.g., "cs_test_xxx")
    ///   - paymentMethod: The ID of the payment method to use for confirmation (payment method must have billing email)
    ///   - expectedAmount: The expected amount for validation
    ///   - expectedPaymentMethodType: The expected payment method type (e.g., "card")
    ///   - returnURL: Optional return URL for redirect-based payment methods
    ///   - shipping: Optional shipping details
    ///   - paymentMethodOptions: Optional payment method options. BLIK code is extracted and passed as top-level `blik_code` parameter.
    ///   - clientAttributionMetadata: Optional client attribution metadata for analytics
    ///   - passiveCaptchaToken: Optional hCaptcha challenge response token
    /// - Returns: CheckoutSessionConfirmResponse containing the confirmation result
    func confirmCheckoutSession(
        sessionId: String,
        paymentMethod: String,
        expectedAmount: Int,
        expectedPaymentMethodType: String,
        returnURL: String? = nil,
        shipping: STPPaymentIntentShippingDetailsParams? = nil,
        paymentMethodOptions: STPConfirmPaymentMethodOptions? = nil,
        clientAttributionMetadata: STPClientAttributionMetadata? = nil,
        passiveCaptchaToken: String? = nil
    ) async throws -> CheckoutSessionConfirmResponse {
        var parameters: [String: Any] = [
            "payment_method": paymentMethod,
            "expected_amount": expectedAmount,
            "expected_payment_method_type": expectedPaymentMethodType,
            "expand": [
                "payment_intent",
                "payment_intent.payment_method",
                "setup_intent",
                "setup_intent.payment_method",
            ],
        ]

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

        return try await APIRequest<CheckoutSessionConfirmResponse>.post(
            with: self,
            endpoint: "payment_pages/\(sessionId)/confirm",
            parameters: parameters
        )
    }
}
