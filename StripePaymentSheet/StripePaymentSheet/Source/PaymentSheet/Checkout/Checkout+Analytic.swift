//
//  Checkout+Analytic.swift
//  StripePaymentSheet
//
//  Created by Yuki Tokuhiro on 7/10/26.
//

@_spi(STP) import StripeCore
@_spi(STP) import StripePayments

struct UnexpectedCheckoutElementsErrorAnalytic: Analytic {
    enum ErrorCode: String {
        case paymentElementPresentingViewControllerUnavailable =
            "payment_element_presenting_view_controller_unavailable"
        case shippingAddressElementPresentingViewControllerUnavailable =
            "shipping_address_element_presenting_view_controller_unavailable"
        case paymentPagesResponseParsingFailed =
            "payment_pages_response_parsing_failed"
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

func logUnexpectedCheckoutElementsErrorAndAssert(
    _ message: String,
    apiClient: STPAPIClient,
    file: StaticString = #file,
    line: UInt = #line,
    analyticsClient: STPAnalyticsClientProtocol = STPAnalyticsClient.sharedClient
) {
    analyticsClient.log(
        analytic: ErrorAnalytic(
            event: .unexpectedCheckoutElementsError,
            error: CheckoutError.unknown(debugDescription: message),
            additionalNonPIIParams: ["error_message": message]
        ),
        apiClient: apiClient
    )
    stpAssertionFailure(message, file: file, line: line)
}

func reportUnexpectedPaymentPagesParsingError(
    _ error: Error,
    apiClient: STPAPIClient,
    analyticsClient: STPAnalyticsClientProtocol = STPAnalyticsClient.sharedClient
) {
    let errorMessage = "Failed to parse Payment Pages response: \(String(describing: error))"
    stpAssertionFailure(errorMessage)
    analyticsClient.log(
        analytic: UnexpectedCheckoutElementsErrorAnalytic(
            errorCode: .paymentPagesResponseParsingFailed,
            errorMessage: errorMessage
        ),
        apiClient: apiClient
    )
}
