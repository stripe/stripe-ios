//
//  APIErrorContext.swift
//  StripeCryptoOnramp
//
//  Created by Michael Liberatore on 5/28/26.
//

import Foundation
@_spi(STP) import StripeCore

/// A type that stores shared API error context.
///
/// Used to keep `StripeCryptoOnrampAPIError` conformers from needing to duplicate all property declarations, and instead use a concrete type, `APIErrorContext`, to store properties common to all API errors.
@_spi(CryptoOnrampAlpha)
public protocol APIErrorContextProviding {

    /// Shared API error context used to expose diagnostics and build developer-facing messages.
    var context: APIErrorContext { get }
}

@_spi(CryptoOnrampAlpha)
public extension APIErrorContextProviding {

    /// A URL to documentation for this error, if one is available.
    var docURL: URL? {
        return context.docURL
    }

    /// The original error that was mapped to this error, if one is available.
    var underlyingError: Swift.Error? {
        return context.underlyingError
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
}

/// Contains the common properties of all API error types.
@_spi(CryptoOnrampAlpha)
public struct APIErrorContext {

    /// The backend `reason` value associated with this error, if one is available.
    public var reason: String?

    /// The SDK operation that was running when this error occurred.
    public var operation: String

    /// The bundle identifier for the app using the SDK, if one is available.
    public var appIdentifier: String?

    /// The Stripe mode associated with this error, if it can be determined.
    public var mode: String?

    /// The Stripe iOS SDK version.
    public var sdkVersion: String

    /// The backend API error code associated with this error, if one is available.
    public var apiErrorCode: String?

    /// The backend API error type associated with this error, if one is available.
    public var apiErrorType: String?

    /// The backend developer-facing API error message associated with this error, if one is available.
    public var apiErrorMessage: String?

    /// The backend user-facing API error message associated with this error, if one is available.
    public var apiUserMessage: String?

    /// A URL to documentation for this error, if one is available.
    public var docURL: URL?

    /// The original error that was mapped to this error.
    public var underlyingError: Swift.Error

    /// Creates shared API error context.
    ///
    /// - Parameters:
    ///   - reason: The backend `reason` value associated with this error, if one is available.
    ///   - operation: The SDK operation that was running when this error occurred.
    ///   - appIdentifier: The bundle identifier for the app using the SDK, if one is available.
    ///   - mode: The Stripe mode associated with this error, if it can be determined.
    ///   - sdkVersion: The Stripe iOS SDK version.
    ///   - apiErrorCode: The backend API error code associated with this error, if one is available.
    ///   - apiErrorType: The backend API error type associated with this error, if one is available.
    ///   - apiErrorMessage: The backend developer-facing API error message associated with this error, if one is available.
    ///   - apiUserMessage: The backend user-facing API error message associated with this error, if one is available.
    ///   - docURL: A URL to documentation for this error, if one is available.
    ///   - underlyingError: The original error that was mapped to this error.
    public init(
        reason: String?,
        operation: String,
        appIdentifier: String?,
        mode: String?,
        sdkVersion: String,
        apiErrorCode: String?,
        apiErrorType: String?,
        apiErrorMessage: String?,
        apiUserMessage: String?,
        docURL: URL?,
        underlyingError: Swift.Error
    ) {
        self.reason = reason
        self.operation = operation
        self.appIdentifier = appIdentifier
        self.mode = mode
        self.sdkVersion = sdkVersion
        self.apiErrorCode = apiErrorCode
        self.apiErrorType = apiErrorType
        self.apiErrorMessage = apiErrorMessage
        self.apiUserMessage = apiUserMessage
        self.docURL = docURL
        self.underlyingError = underlyingError
    }

    /// The Stripe API request ID associated with this error, if one is available.
    public var requestID: String? {
        guard let stripeError = underlyingError as? StripeError,
              case let .apiError(apiError) = stripeError else {
            return nil
        }
        return apiError.requestID
    }

    /// Returns the backend API error code, or a fallback code if the backend code is unavailable.
    ///
    /// - Parameter fallback: The SDK-defined error code to use if the backend API error code is unavailable.
    func code(fallback: String) -> String {
        return apiErrorCode ?? fallback
    }

    /// Returns a developer-facing description with diagnostic context and a suggested next step.
    ///
    /// - Parameters:
    ///   - summary: A short description of the error.
    ///   - nextStep: A suggested action for resolving the error.
    func developerDescription(summary: String, nextStep: String) -> String {
        let context = [
            "  - operation: \(operation)",
            appIdentifier.map { "  - app_id: \($0)" },
            mode.map { "  - mode: \($0)" },
            reason.map { "  - reason: \($0)" },
            requestID.map { "  - request_id: \($0)" },
            apiErrorCode.map { "  - code: \($0)" },
            apiErrorType.map { "  - type: \($0)" },
        ].compactMap { $0 }

        var lines = [
            "Summary",
            "  \(summary)",
            "",
            "Context",
            context.joined(separator: "\n"),
            "",
            "Next step",
            "  \(nextStep)",
        ]

        if let docURL {
            lines.append(contentsOf: [
                "",
                "Docs",
                "  \(docURL.absoluteString)",
            ])
        }

        lines.append(contentsOf: [
            "",
            "SDK",
            "  stripe-ios@\(sdkVersion)",
        ])

        return lines.joined(separator: "\n")
    }
}
