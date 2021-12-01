//
//  StripeError.swift
//  StripeCore
//
//  Created by David Estes on 8/11/21.
//

import Foundation

/// Error codes returned from STPAPIClient
enum StripeError: Error {
    /// The server returned an API error
    case apiError(StripeAPIError)

    /// Localized description of the error
    public var localizedDescription: String {
        return errorDescription ?? NSError.stp_unexpectedErrorMessage()
    }
}

// MARK: - LocalizedError

extension StripeError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .apiError(let apiError):
            return apiError.errorUserInfoString(key: NSLocalizedDescriptionKey)
        }
    }

    var failureReason: String? {
        switch self {
        case .apiError(let apiError):
            return apiError.errorUserInfoString(key: NSLocalizedFailureReasonErrorKey)
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .apiError(let apiError):
            return apiError.errorUserInfoString(key: NSLocalizedRecoverySuggestionErrorKey)
        }
    }

    var helpAnchor: String? {
        switch self {
        case .apiError(let apiError):
            return apiError.errorUserInfoString(key: NSHelpAnchorErrorKey)
        }
    }
}
