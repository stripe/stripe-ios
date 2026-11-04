//
//  Checkout+Analytic.swift
//  StripePaymentSheet
//
//  Created by Yuki Tokuhiro on 7/10/26.
//

@_spi(InternalOnlyAPI) import StripeCore
@_spi(InternalOnlyAPI) import StripePayments

/// Logs and asserts an unexpected Checkout Elements error.
@discardableResult
func logUnexpectedCheckoutElementsError(
    _ nonPIIErrorMessage: String,
    code: String = "",
    apiClient: STPAPIClient = .shared,
    analyticsClient: STPAnalyticsClientProtocol = STPAnalyticsClient.sharedClient
) -> UnexpectedError {
    logUnexpectedError(
        nonPIIErrorMessage,
        event: .unexpectedCheckoutElementsError,
        code: code,
        apiClient: apiClient,
        analyticsClient: analyticsClient
    )
}
