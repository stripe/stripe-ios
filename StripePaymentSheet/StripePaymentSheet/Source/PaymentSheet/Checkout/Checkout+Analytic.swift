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
        /// The Session's payment option is Apple Pay, but Payment Element's configuration doesn't allow Apple Pay.
        case paymentElementApplePayUnavailable =
            "payment_element_apple_pay_unavailable"
        /// Payment Element's FlowController and EmbeddedPaymentElement had different default payment options on first load.
        case paymentElementInitialPaymentOptionMismatch =
            "payment_element_initial_payment_option_mismatch"
        /// PaymentHandler returned an action status this SDK doesn't handle.
        case paymentHandlerUnknownActionStatus =
            "payment_handler_unknown_action_status"
        /// /confirm returned `requires_action` without a PaymentIntent or SetupIntent.
        case confirmRequiresActionWithoutIntent =
            "confirm_requires_action_without_intent"
        /// /confirm returned an expired Session.
        case confirmSessionExpired =
            "confirm_session_expired"
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
        /// Link reported a completed Checkout confirmation without the confirmed Session.
        case linkCompletedWithoutSession =
            "link_completed_without_session"
        /// Link asked Checkout to confirm a payment option other than Link.
        case linkUnsupportedPaymentOption =
            "link_unsupported_payment_option"
        /// The Apple Pay sheet finished in an error state without a result.
        case applePayErrorStateWithoutResult =
            "apple_pay_error_state_without_result"
        /// PassKit rejected the Apple Pay payment request built from the Session.
        case applePayPaymentRequestInvalid =
            "apple_pay_payment_request_invalid"
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
