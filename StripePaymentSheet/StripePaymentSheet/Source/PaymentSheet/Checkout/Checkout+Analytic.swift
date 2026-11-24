//
//  Checkout+Analytic.swift
//  StripePaymentSheet
//
//  Created by Yuki Tokuhiro on 7/10/26.
//

@_spi(InternalOnlyAPI) import StripeCore
@_spi(InternalOnlyAPI) import StripePayments

struct UnexpectedCheckoutElementsErrorAnalytic: Analytic {
    /// Identifies a distinct unexpected error. Reuse a case only for the same error, and never rename a shipped case.
    enum ErrorCode: String {
        /// Confirmation found a Session payment option but no PaymentElement to confirm it with.
        case paymentOptionWithoutPaymentElement =
            "payment_option_without_payment_element"
        /// Confirmation found the FlowController-backed PaymentElement has no payment option, but the Session has one.
        case flowControllerPaymentOptionOutOfSync =
            "flow_controller_payment_option_out_of_sync"
        /// Confirmation found the embedded PaymentElement has no payment option, but the Session has one.
        case embeddedPaymentElementPaymentOptionOutOfSync =
            "embedded_payment_element_payment_option_out_of_sync"
        /// /poll reported `not_started` after /confirm was accepted.
        case confirmPollNotStarted =
            "confirm_poll_not_started"
        /// Express Checkout Element asked to confirm, but Checkout has no Express Checkout Element configuration.
        case expressCheckoutElementConfigurationUnavailable =
            "express_checkout_element_configuration_unavailable"
        /// Express Checkout Element asked to confirm with Apple Pay, but Checkout has no Apple Pay merchant ID.
        case expressCheckoutElementApplePayMerchantIdUnavailable =
            "express_checkout_element_apple_pay_merchant_id_unavailable"
        /// Express Checkout Element asked to confirm with Link, but no view controller could present Link.
        case expressCheckoutElementLinkPresentingViewControllerUnavailable =
            "express_checkout_element_link_presenting_view_controller_unavailable"
        /// `PKPaymentAuthorizationController.canMakePayments()` returned false when starting Apple Pay.
        case applePayCannotMakePayments =
            "apple_pay_cannot_make_payments"
        /// PassKit rejected the Apple Pay payment request built from the Session.
        case applePayPaymentRequestInvalid =
            "apple_pay_payment_request_invalid"
        /// PassKit failed to present the Apple Pay sheet.
        case applePayPresentationFailed =
            "apple_pay_presentation_failed"
        /// `PaymentElement.present(from:)` could not find a view controller to present from.
        case paymentElementPresentingViewControllerUnavailable =
            "payment_element_presenting_view_controller_unavailable"
        /// The customer interacted with the PaymentElement's view, but no view controller could present the resulting sheet.
        case paymentElementViewPresentingViewControllerUnavailable =
            "payment_element_view_presenting_view_controller_unavailable"
        /// `ShippingAddressElement.present(from:)` could not find a view controller to present from.
        case shippingAddressElementPresentingViewControllerUnavailable =
            "shipping_address_element_presenting_view_controller_unavailable"
        /// A CheckoutClient response failed to decode as `CheckoutClientAPIResponse` (/init, /update, /confirm, /retrieve).
        case checkoutClientResponseParsingFailed =
            "checkout_client_response_parsing_failed"
        /// A CheckoutClient /poll response failed to decode as `CheckoutClientPollResponse`.
        case checkoutClientPollResponseParsingFailed =
            "checkout_client_poll_response_parsing_failed"
    }

    let errorCode: ErrorCode
    let errorMessage: String

    var event: STPAnalyticEvent {
        return .unexpectedCheckoutElementsError
    }

    var params: [String: Any] {
        return [
            "error_code": errorCode.rawValue,
            "error_message": errorMessage,
        ]
    }
}

/// Logs an unexpected Checkout Elements error. `STPAnalyticsClient` asserts when it logs unexpected errors.
func logUnexpectedCheckoutElementsErrorAndAssert(
    _ errorCode: UnexpectedCheckoutElementsErrorAnalytic.ErrorCode,
    message: String,
    apiClient: STPAPIClient,
    analyticsClient: STPAnalyticsClientProtocol = STPAnalyticsClient.sharedClient
) {
    analyticsClient.log(
        analytic: UnexpectedCheckoutElementsErrorAnalytic(errorCode: errorCode, errorMessage: message),
        apiClient: apiClient
    )
}

func reportUnexpectedCheckoutClientParsingError(
    _ error: Error,
    errorCode: UnexpectedCheckoutElementsErrorAnalytic.ErrorCode,
    apiClient: STPAPIClient,
    analyticsClient: STPAnalyticsClientProtocol = STPAnalyticsClient.sharedClient
) {
    logUnexpectedCheckoutElementsErrorAndAssert(
        errorCode,
        message: "Failed to parse Checkout Client response: \(String(describing: error))",
        apiClient: apiClient,
        analyticsClient: analyticsClient
    )
}
