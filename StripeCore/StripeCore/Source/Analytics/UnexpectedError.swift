//
//  UnexpectedError.swift
//  StripeCore
//
//  Created by Yuki on 11/2/26.
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

import Foundation

/// An error for an "unexpected error" - something which should *never* happen i.e. programming error in the SDK, *not* a condition a merchant/customer caused or a 500 server error.
/// - Note: Unexpected errors are observed and alerted on.
@_spi(InternalOnlyAPI) public struct UnexpectedError: Error, LocalizedError, AnalyticLoggableError, CustomStringConvertible {
    /// Must not contain PII — this value is sent to analytics and included in the debug-only assertion message.
    public let nonPIIErrorMessage: String

    /// A stable short code for dashboards/alerting. Defaults to "unexpected".
    public let code: String

    public init(nonPIIErrorMessage: String, code: String = "unexpected") {
        self.nonPIIErrorMessage = nonPIIErrorMessage
        self.code = code
    }

    // MARK: - LocalizedError

    /// A generic, actually-localized message. The diagnostic detail lives in `nonPIIErrorMessage`,
    /// surfaced via analytics and the debug assertion — not to merchants or customers.
    public var errorDescription: String? {
        NSError.stp_unexpectedErrorMessage()
    }

    // MARK: - CustomStringConvertible

    public var description: String {
        nonPIIErrorMessage
    }

    // MARK: - AnalyticLoggableError

    public var analyticsErrorType: String {
        "UnexpectedError"
    }

    public var analyticsErrorCode: String {
        code
    }

    public var additionalNonPIIErrorDetails: [String: Any] {
        ["error_message": nonPIIErrorMessage]
    }
}

/// Logs an "unexpected error" - something which should *never* happen i.e. programming error in the SDK, *not* a condition a merchant/customer caused or a 500 server error.
/// Throwing call site can write `throw logUnexpectedError(...)`.
/// Non-throwing call site can write `logUnexpectedError(...)`.
///
/// - Note: Unexpected errors are observed and alerted on.
@_spi(InternalOnlyAPI) public func logUnexpectedError(
    _ nonPIIErrorMessage: String,
    event: STPAnalyticEvent,
    code: String = "unexpected",
    apiClient: STPAPIClient = .shared,
    analyticsClient: STPAnalyticsClientProtocol = STPAnalyticsClient.sharedClient
) -> UnexpectedError {
    let error = UnexpectedError(nonPIIErrorMessage: nonPIIErrorMessage, code: code)
    analyticsClient.log(
        analytic: ErrorAnalytic(
            event: event,
            error: error,
            // Dashboards and alerts read the top-level message. AnalyticLoggableError also
            // preserves it under error_details when the returned error is serialized later.
            additionalNonPIIParams: ["error_message": nonPIIErrorMessage]
        ),
        apiClient: apiClient
    )
    return error
}
