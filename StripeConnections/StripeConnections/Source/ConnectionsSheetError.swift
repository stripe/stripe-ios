//
//  ConnectionsSheetError.swift
//  StripeConnections
//
//  Created by Vardges Avetisyan on 11/17/21.
//

import Foundation
@_spi(STP) import StripeCore

public enum ConnectionsSheetError: Error, LocalizedError {
    /// An unknown error.
    case unknown(debugDescription: String)

    /// Localized description of the error
    public var localizedDescription: String {
        return NSError.stp_unexpectedErrorMessage()
    }
}

/// :nodoc:
@_spi(STP) extension ConnectionsSheetError: AnalyticLoggableError {

    /// The error code
    public var errorCode: Int {
        switch self {
        case .unknown:
            return 0
        }
    }

    /// Serializes this error
    /// - Returns: an error with a domain and code
    public func serializeForLogging() -> [String : Any] {
        return [
            "domain": "Stripe.\(ConnectionsSheetError.self)",
            "code": errorCode]
    }
}
