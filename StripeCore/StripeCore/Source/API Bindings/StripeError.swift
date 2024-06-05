//
//  StripeError.swift
//  StripeCore
//
//  Created by David Estes on 8/11/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation

/// Error codes returned from STPAPIClient.
@_spi(STP) public enum StripeError: Error {
    /// The server returned an API error.
    case apiError(StripeAPIError)

    /// The request was invalid.
    case invalidRequest

    /// Localized description of the error.
    public var localizedDescription: String {
        return errorDescription ?? NSError.stp_unexpectedErrorMessage()
    }
}

extension StripeError: AnalyticLoggableError {
    public var additionalNonPIIErrorDetails: [String: Any] {
        [:]
    }
    public var analyticsErrorCode: String {
        switch self {
        case .invalidRequest:
            "invalidRequest"
        case .apiError(let stripeAPIError):
            stripeAPIError.code ?? ""
        }
    }

    public var analyticsErrorType: String {
        switch self {
        case .invalidRequest:
            return String(reflecting: type(of: self))
        case .apiError(let stripeAPIError):
            return stripeAPIError.type.rawValue
        }
    }
}

// MARK: - LocalizedError

extension StripeError: LocalizedError {
    @_spi(STP) public var errorDescription: String? {
        switch self {
        case .apiError(let apiError):
            return apiError.errorUserInfoString(key: NSLocalizedDescriptionKey)
        case .invalidRequest:
            return nil
        }
    }

    @_spi(STP) public var failureReason: String? {
        switch self {
        case .apiError(let apiError):
            return apiError.errorUserInfoString(key: NSLocalizedFailureReasonErrorKey)
        case .invalidRequest:
            return nil
        }
    }

    @_spi(STP) public var recoverySuggestion: String? {
        switch self {
        case .apiError(let apiError):
            return apiError.errorUserInfoString(key: NSLocalizedRecoverySuggestionErrorKey)
        case .invalidRequest:
            return nil
        }
    }

    @_spi(STP) public var helpAnchor: String? {
        switch self {
        case .apiError(let apiError):
            return apiError.errorUserInfoString(key: NSHelpAnchorErrorKey)
        case .invalidRequest:
            return nil
        }
    }
}
