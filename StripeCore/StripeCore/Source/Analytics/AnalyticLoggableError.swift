//
//  AnalyticLoggableError.swift
//  StripeCore
//
//  Created by Nick Porter on 9/2/21.
//

import Foundation

/// Defines a common loggable error to our analytics service
@_spi(STP) public protocol AnalyticLoggableError: Error {
    
    /// Serializes this error for analytics logging
    /// - Returns: A dictionary representing this error, not containing any PII or PDE
    func analyticLoggableSerializeForLogging() -> [String: Any]
}

@_spi(STP) extension Error {

    public func serializeForLogging() -> [String : Any] {
        if let loggableError = self as? AnalyticLoggableError {
            return loggableError.analyticLoggableSerializeForLogging()
        }
        let nsError = self as NSError
        return [
            "domain": nsError.domain,
            "code": nsError.code
        ]
    }

}
