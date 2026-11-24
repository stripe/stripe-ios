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
        case paymentOptionWithoutPaymentElement =
            "payment_option_without_payment_element"
        case flowControllerPaymentOptionOutOfSync =
            "flow_controller_payment_option_out_of_sync"
        case embeddedPaymentElementPaymentOptionOutOfSync =
            "embedded_payment_element_payment_option_out_of_sync"
        case confirmPollNotStarted =
            "confirm_poll_not_started"
        case expressCheckoutElementConfigurationUnavailable =
            "express_checkout_element_configuration_unavailable"
        case expressCheckoutElementApplePayMerchantIdUnavailable =
            "express_checkout_element_apple_pay_merchant_id_unavailable"
        case expressCheckoutElementLinkPresentingViewControllerUnavailable =
            "express_checkout_element_link_presenting_view_controller_unavailable"
        case applePayCannotMakePayments =
            "apple_pay_cannot_make_payments"
        case applePayPaymentRequestInvalid =
            "apple_pay_payment_request_invalid"
        case applePayPresentationFailed =
            "apple_pay_presentation_failed"
        case paymentElementPresentingViewControllerUnavailable =
            "payment_element_presenting_view_controller_unavailable"
        case paymentElementViewPresentingViewControllerUnavailable =
            "payment_element_view_presenting_view_controller_unavailable"
        case shippingAddressElementPresentingViewControllerUnavailable =
            "shipping_address_element_presenting_view_controller_unavailable"
        case checkoutClientResponseParsingFailed =
            "checkout_client_response_parsing_failed"
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
    apiClient: STPAPIClient,
    analyticsClient: STPAnalyticsClientProtocol = STPAnalyticsClient.sharedClient
) {
    let errorMessage = "Failed to parse Checkout Client response: \(String(describing: error))"
    stpAssertionFailure(errorMessage)
    analyticsClient.log(
        analytic: UnexpectedCheckoutElementsErrorAnalytic(
            errorCode: .checkoutClientResponseParsingFailed,
            errorMessage: errorMessage
        ),
        apiClient: apiClient
    )
}
