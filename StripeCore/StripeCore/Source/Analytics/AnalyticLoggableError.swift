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
    func serializeForLogging() -> [String: Any]
}

/// Implements `AnalyticLoggableError` for `NSError`
@_spi(STP) extension NSError: AnalyticLoggableError {

    public func serializeForLogging() -> [String : Any] {
        return [
            "domain": domain,
            "code": code
        ]
    }
    
}
