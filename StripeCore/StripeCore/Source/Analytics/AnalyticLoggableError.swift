//
//  AnalyticLoggableError.swift
//  StripeCore
//
//  Created by Nick Porter on 9/2/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation

/// Defines a common loggable error to our analytics service.
@_spi(STP) public protocol AnalyticLoggableError: Error {

    /// Serializes this error for analytics logging.
    ///
    /// - Returns: A dictionary representing this error, not containing any PII or PDE
    func analyticLoggableSerializeForLogging() -> [String: Any]
}

/// Error types that conform to this protocol and String-based RawRepresentable
/// will automatically serialize the rawValue for analytics logging.
@_spi(STP) public protocol AnalyticLoggableStringError: Error {
    var loggableType: String { get }
}

@_spi(STP) extension AnalyticLoggableStringError
where Self: RawRepresentable, Self.RawValue == String {
    public var loggableType: String {
        return rawValue
    }
}

@_spi(STP) extension Error {
    /// Serialize an Error for logging, suitable for the Identity and Financial Connections SDK.
    // TODO: Rename to serializeForIdentityAndFinancialConnectionsSDKLogging()
    public func serializeForLogging() -> [String: Any] {
        if let loggableError = self as? AnalyticLoggableError {
            return loggableError.analyticLoggableSerializeForLogging()
        }
        let nsError = self as NSError

        var payload: [String: Any] = [
            "domain": nsError.domain,
        ]

        if let stringError = self as? AnalyticLoggableStringError {
            payload["type"] = stringError.loggableType
        } else {
            payload["code"] = nsError.code
        }

        return payload
    }

    /// This is like `serializeForLogging` but returns a single String instead of a dict.
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
        let errorType = Self.extractErrorType(from: self)
        let errorCode = Self.extractErrorCode(from: self)

        return [
            "error_type": errorType,
            "error_code": errorCode,
        ]
    }

    /// Extracts a value suitable for the `"error_type"` analytic parameter
    /// - For Stripe API errors, the error’s [type](https://docs.stripe.com/api/errors#errors-type) e.g. “invalid_request_error”.
    /// - For Swift errors, the fully qualified type name e.g. “StripePaymentSheet.LinkURLGeneratorError”.
    /// - For NSErrors, the error domain e.g. “NSURLErrorDomain”.
    static func extractErrorType(from error: Error) -> String {
        if type(of: error) is NSError.Type {
            let error = error as NSError
            if error.domain == STPError.stripeDomain, let stripeAPIErrorType = error.userInfo[STPError.stripeErrorTypeKey] as? String {
                // For Stripe API Error, use the error type key's value
                return stripeAPIErrorType
            } else {
                // Default behavior for other errors.
                // Note: For Swift Error enums, `domain` is the type name
                // e.g. `LinkURLGeneratorError.noPublishableKey` -> "StripePaymentSheet.LinkURLGeneratorError"
                return "\(error.domain)"
            }
        } else {
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
        if let self = self as? (any RawRepresentable), let rawValueString = self.rawValue as? String {
            // For Swift string enums, use the raw value
            return rawValueString
        } else if mirror.displayStyle == .enum {
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

extension Error {
    var errorType: String {
        return (self as NSError).domain
    }
}
