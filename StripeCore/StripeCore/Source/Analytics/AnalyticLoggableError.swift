//
//  AnalyticLoggableError.swift
//  StripeCore
//
//  Created by Nick Porter on 9/2/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation

/// Conform your Error to this protocol to override the parameters that get logged when you either:
/// 1. Use `ErrorAnalytic` to send error analytics.
/// 2. Build your own `Analytic` and use `serializeForV1Analytics`.
protocol AnalyticLoggableError: Error {
    /// The value used for `"error_type"` in the analytics payload.
    /// The default implementation uses `Error.extractErrorType`
    var errorType: String { get }

    /// The value used for `"error_code"` in the analytics payload.
    /// The default implementation uses `Error.errorCode`
    var errorCode: String { get }

    /// Additional, non-PII/PDE details about the error.
    /// If non-empty, this is sent as the value for `"error_details"` in the analytics payload.
    var additionalNonPIIErrorDetails: [String: Any] { get }
}

// MARK: Default implementation
extension AnalyticLoggableError {
    var errorType: String {
        Self.extractErrorType(from: self)
    }

    var errorCode: String {
        Self.extractErrorCode(from: self)
    }

    var additionalNonPIIErrorDetails: [String: Any] {
        return [:]
    }
}

extension AnalyticLoggableError where Self: Error {}

// MARK: - Error extension methods that serialize errors for analytics logging
@_spi(STP) extension Error {
    /// This is like `serializeForV2Logging` but returns a single String instead of a dict.
    /// TODO(MOBILESDK-1547) I don't think pattern is very good but it's here to share between PaymentSheet and STPPaymentContext. Please rethink before spreading its usage.
    public func makeSafeLoggingString() -> String {
        let error = self as NSError
        if error.domain == STPError.stripeDomain, let code = STPErrorCode(rawValue: error.code) {
            // An error from our networking layer
            return code.description
        } else {
            // Default behavior for other errors.
            // Note: For Swift Error enums, `domain` is the type name and `code` is the case index
            // e.g. `LinkURLGeneratorError.noPublishableKey` -> "StripePaymentSheet.LinkURLGeneratorError, 1"
            return "\(error.domain), \(error.code)"
        }
    }

    /// Serialize an Error for logging to q.stripe.com and the `sdk.analytics_events` table
    ///
    /// It sends the following fields:
    /// - error_type: For Stripe API errors, the error’s [type](https://docs.stripe.com/api/errors#errors-type) e.g. “invalid_request_error”.
    ///           For Swift errors, the fully qualified type name e.g. “StripePaymentSheet.LinkURLGeneratorError”.
    ///           For NSErrors, the error domain e.g. “NSURLErrorDomain”.
    /// - error_code: For Stripe API errors, the error's code e.g. "invalid_number".
    ///            For NSErrors, the error code e.g. “-1009”.
    ///            For Swift errors, the enum case name as a string for Swift errors e.g. “noPublishableKey”.
    public func serializeForV1Analytics() -> [String: Any] {
        let errorType: String = {
            if let analyticLoggableError = self as? AnalyticLoggableError {
                analyticLoggableError.errorType
            } else {
                Self.extractErrorType(from: self)
            }
        }()
        let errorCode: String = {
            if let analyticLoggableError = self as? AnalyticLoggableError {
                analyticLoggableError.errorCode
            } else {
                Self.extractErrorCode(from: self)
            }
        }()
        var params: [String: Any] = [
            "error_type": errorType,
            "error_code": errorCode,
        ]
        if let analyticLoggableError = self as? AnalyticLoggableError {
            params["error_details"] = analyticLoggableError.additionalNonPIIErrorDetails
        }
        return params
    }

    /// Extracts a value suitable for the `"error_type"` analytic parameter
    /// - For Stripe API errors, the error’s [type](https://docs.stripe.com/api/errors#errors-type) e.g. “invalid_request_error”.
    /// - For Swift errors, the fully qualified type name e.g. “StripePaymentSheet.LinkURLGeneratorError”.
    /// - For NSErrors, the error domain e.g. “NSURLErrorDomain”.
    static func extractErrorType(from error: Error) -> String {
        if type(of: error) is NSError.Type {
            // Note: checking `error as NSError` always succeeds because Swift errors are bridged - this ensures the error is an instance of NSError.
            let error = error as NSError
            if error.domain == STPError.stripeDomain, let stripeAPIErrorType = error.userInfo[STPError.stripeErrorTypeKey] as? String {
                // For Stripe API Error, use the error type key's value
                return stripeAPIErrorType
            } else {
                // For other NSErrors, use the domain
                return "\(error.domain)"
            }
        } else {
            // This is a Swift Error, use the qualified type name e.g. "Swift.DecodingError" or "StripePaymentSheet.PaymentSheetError"
            return String(reflecting: type(of: error))
        }
    }

    /// Extracts a value suitable for the `"error_code"` analytic parameter
    /// - For Stripe API errors, the error's code e.g. "invalid_number".
    /// - For NSErrors, the error code e.g. “-1009”.
    /// - For Swift errors, the enum case name as a string for Swift errors e.g. “noPublishableKey”.
    static func extractErrorCode(from error: Error) -> String {
        // Note: We explicitly avoid using String(describing:) or similar to prevent the edge case where an Error conforms to CustomDebugStringConvertible or similar and puts PII in the `description`
        let mirror = Mirror(reflecting: error)
        if mirror.displayStyle == .enum {
            if let caseLabel = mirror.children.first?.label {
                // For enums with associated values, this returns the name of the case e.g. DecodingError.keyNotFound(...) -> "keyNotFound"
                return caseLabel
            } else {
                // For enum cases without associated values, reflection does not contain the case name. Since enums can't contain stored properties (besides associated values), we can safely assume String(describing:) doesn't contain PII; any PII would need to have been captured in an associated value.
                return "\(error)"
            }
        }
        let error = error as NSError
        if error.domain == STPError.stripeDomain, let stripeAPIErrorCode = error.userInfo[STPError.stripeErrorCodeKey] as? String {
            // For Stripe API Error, use the error code key's value
            return stripeAPIErrorCode
        } else {
            // Default: Cast to Error and use the code.
            return String((error as NSError).code)
        }
    }
}
