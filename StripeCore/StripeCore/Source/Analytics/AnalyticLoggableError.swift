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
}
