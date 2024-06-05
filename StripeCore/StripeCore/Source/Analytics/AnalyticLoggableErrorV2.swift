//
//  AnalyticLoggableErrorV2.swift
//  StripeCore
//
//  Created by Nick Porter on 9/2/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation

/// Defines a common loggable error to our analytics service for Identity and FinancialConnections SDKs.
@_spi(STP) public protocol AnalyticLoggableErrorV2: Error {

    /// Serializes this error for analytics logging.
    ///
    /// - Returns: A dictionary representing this error, not containing any PII or PDE
    func analyticLoggableSerializeForLogging() -> [String: Any]
}

/// Error types that conform to this protocol and String-based RawRepresentable
/// will automatically serialize the rawValue for analytics logging.
@_spi(STP) public protocol AnalyticLoggableStringErrorV2: Error {
    var loggableType: String { get }
}

@_spi(STP) extension AnalyticLoggableStringErrorV2
where Self: RawRepresentable, Self.RawValue == String {
    public var loggableType: String {
        return rawValue
    }
}

@_spi(STP) extension Error {
    /// Serialize an Error for logging, suitable for the Identity and Financial Connections SDK.
    public func serializeForV2Logging() -> [String: Any] {
        if let loggableError = self as? AnalyticLoggableErrorV2 {
            return loggableError.analyticLoggableSerializeForLogging()
        }
        let nsError = self as NSError

        var payload: [String: Any] = [
            "domain": nsError.domain,
        ]

        if let stringError = self as? AnalyticLoggableStringErrorV2 {
            payload["type"] = stringError.loggableType
        } else {
            payload["code"] = nsError.code
        }

        return payload
    }
}

extension StripeError: AnalyticLoggableErrorV2 {
    public func analyticLoggableSerializeForLogging() -> [String: Any] {
        var code: Int
        switch self {
        case .apiError:
            code = 0
        case .invalidRequest:
            code = 1
        }

        return [
            "domain": (self as NSError).domain,
            "code": code,
        ]
    }
}
