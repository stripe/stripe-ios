//
//  APIErrorContext.swift
//  StripeCryptoOnramp
//
//  Created by Michael Liberatore on 5/28/26.
//

import Foundation
@_spi(STP) import StripeCore

/// Contains the common properties of all API error types.
@_spi(CryptoOnrampAlpha)
public struct APIErrorContext {

    /// The backend `reason` value associated with this error, if one is available.
    public let reason: String?

    /// The SDK operation that was running when this error occurred.
    public let operation: String

    /// The bundle identifier for the app using the SDK, if one is available.
    public let appIdentifier: String?

    /// The Stripe mode associated with this error, if it can be determined.
    public let mode: String?

    /// The Stripe iOS SDK version.
    public let sdkVersion: String

    /// The backend API error code associated with this error, if one is available.
    public let apiErrorCode: String?

    /// The backend API error type associated with this error, if one is available.
    public let apiErrorType: String?

    /// The backend developer-facing API error message associated with this error, if one is available.
    public let apiErrorMessage: String?

    /// The backend user-facing API error message associated with this error, if one is available.
    public let apiUserMessage: String?

    /// A URL to documentation for this error, if one is available.
    public let docURL: URL?

    /// The original error that was mapped to this error.
    public let underlyingError: Swift.Error

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
