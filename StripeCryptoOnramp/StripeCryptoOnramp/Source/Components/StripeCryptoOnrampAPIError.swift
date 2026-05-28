//
//  StripeCryptoOnrampAPIError.swift
//  StripeCryptoOnramp
//
//  Created by Michael Liberatore on 5/28/26.
//

import Foundation

/// A rich Crypto Onramp error backed by a Stripe API error.
@_spi(CryptoOnrampAlpha)
public protocol StripeCryptoOnrampAPIError: StripeCryptoOnrampError {

    /// Shared API error context used to expose diagnostics and build developer-facing messages.
    var context: APIErrorContext { get }

    /// The backend `reason` value associated with this error, if one is available.
    var reason: String? { get }

    /// The SDK operation that was running when this error occurred.
    var operation: String { get }

    /// The bundle identifier for the app using the SDK, if one is available.
    var appIdentifier: String? { get }

    /// The Stripe mode associated with this error, if it can be determined.
    var mode: String? { get }

    /// The Stripe iOS SDK version.
    var sdkVersion: String { get }

    /// The backend API error type associated with this error, if one is available.
    var type: String? { get }

    /// The Stripe API request ID associated with this error, if one is available.
    var requestID: String? { get }

    /// The backend developer-facing API error message associated with this error, if one is available.
    var apiMessage: String? { get }

    /// The backend user-facing API error message associated with this error, if one is available.
    var apiUserMessage: String? { get }
}

/// Default protocol implementation to surface values from the underlying `APIErrorContext` for convenience.
@_spi(CryptoOnrampAlpha)
public extension StripeCryptoOnrampAPIError {

    /// A stable code identifying this error.
    var code: String {
        return apiErrorCode ?? "api_error"
    }

    /// The backend `reason` value associated with this error, if one is available.
    var reason: String? {
        return context.reason
    }

    /// The SDK operation that was running when this error occurred.
    var operation: String {
        return context.operation
    }

    /// The bundle identifier for the app using the SDK, if one is available.
    var appIdentifier: String? {
        return context.appIdentifier
    }

    /// The Stripe mode associated with this error, if it can be determined.
    var mode: String? {
        return context.mode
    }

    /// The Stripe iOS SDK version.
    var sdkVersion: String {
        return context.sdkVersion
    }

    /// A URL to documentation for this error, if one is available.
    var docURL: URL? {
        return context.docURL
    }

    /// The original error that was mapped to this error.
    var underlyingError: Swift.Error? {
        return context.underlyingError
    }

    /// The backend API error type associated with this error, if one is available.
    var type: String? {
        return context.apiErrorType
    }

    /// The Stripe API request ID associated with this error, if one is available.
    var requestID: String? {
        return context.requestID
    }

    /// The backend developer-facing API error message associated with this error, if one is available.
    var apiMessage: String? {
        return context.apiErrorMessage
    }

    /// The backend user-facing API error message associated with this error, if one is available.
    var apiUserMessage: String? {
        return context.apiUserMessage
    }

    /// The backend API error code associated with this error, if one is available.
    var apiErrorCode: String? {
        return context.apiErrorCode
    }

    /// The backend API error type associated with this error, if one is available.
    var apiErrorType: String? {
        return type
    }

    /// The backend developer-facing API error message associated with this error, if one is available.
    var apiErrorMessage: String? {
        return apiMessage
    }
}
