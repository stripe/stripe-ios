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

}
