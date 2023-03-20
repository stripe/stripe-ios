//
//  IdentityVerificationSheetError.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 3/3/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeCore

/**
 Errors specific to the `IdentityVerificationSheet`.
 */
public enum IdentityVerificationSheetError: Error {
    /// The provided client secret is invalid.
    case invalidClientSecret
    /// An unknown error.
    case unknown(debugDescription: String)
}

extension IdentityVerificationSheetError: LocalizedError {
    /// Localized description of the error
    public var localizedDescription: String {
        return NSError.stp_unexpectedErrorMessage()
    }
}

extension IdentityVerificationSheetError: CustomDebugStringConvertible {
    public var debugDescription: String {
        switch self {
        case .invalidClientSecret:
            return "Invalid client secret"
        case .unknown(debugDescription: let debugDescription):
            return debugDescription
        }
    }
}

/// :nodoc:
@_spi(STP) extension IdentityVerificationSheetError: AnalyticLoggableError {
    
    /// The error code
    public var errorCode: Int {
        switch self {
        case .invalidClientSecret:
            return 0
        case .unknown:
            return 1
        }
    }
    
    /// Serializes this error
    /// - Returns: an error with a domain and code
    public func analyticLoggableSerializeForLogging() -> [String : Any] {
        return [
            "domain": (self as NSError).domain,
            "code": errorCode
        ]
    }
}
