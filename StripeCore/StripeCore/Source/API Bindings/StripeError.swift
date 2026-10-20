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

    /// The request was invalid and not sent to the API.
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

extension Error {
    /// Whether this API error's localized description includes a live-mode request ID.
    @_spi(STP) public var _stp_hasRequestIDInDescription: Bool {
        if let stripeError = self as? StripeError, case .apiError(let apiError) = stripeError {
            // The formatter only appends a request ID when a description is available.
            return apiError.includeRequestIDInDescription && apiError.requestID?.nonEmpty != nil
                && (!apiError.useServerErrorMessage || apiError.message != nil)
        }
        return (self as NSError).userInfo[STPError.requestIDInDescriptionKey] as? Bool == true
    }

    /// Returns the Stripe error code, if available. Works with modern and legacy Stripe API errors.
    @_spi(STP) public var _stp_error_code: String? {
        if let stripeError = self as? StripeError,
              case let .apiError(stripeAPIError) = stripeError {
            return stripeAPIError.code
        }

        if let errorCodeString = (self as NSError).userInfo[STPError.stripeErrorCodeKey] as? String {
            return errorCodeString
        }

        return nil
    }
}
