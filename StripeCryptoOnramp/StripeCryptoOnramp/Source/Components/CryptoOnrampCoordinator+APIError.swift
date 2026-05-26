//
//  CryptoOnrampCoordinator+APIError.swift
//  StripeCryptoOnramp
//
//  Created by Michael Liberatore on 5/26/26.
//

import Foundation
@_spi(STP) import StripeCore

/// Details from an app attestation API error, enriched with SDK-local diagnostic context.
public struct AppAttestationAPIError: APIErrorContextProviding {

    /// Shared API error context used to expose diagnostics and build developer-facing messages.
    let context: APIErrorContext

    /// Creates an app attestation API error from shared API error context.
    ///
    /// - Parameter context: Shared API error context used to expose diagnostics.
    init(context: APIErrorContext) {
        self.context = context
    }

    // MARK: - LocalizedError

    public var errorDescription: String? {
        return userFacingMessage
    }

    // MARK: - CustomDebugStringConvertible

    public var debugDescription: String {
        return developerDescription
    }

    // MARK: - AppAttestationAPIError

    /// A localized message that can be shown to the app user.
    public var userFacingMessage: String {
        return String.Localized.cryptoOnrampErrorAppAttestationFailed
    }

    /// A developer-facing description with diagnostic details and suggested next steps.
    public var developerDescription: String {
        return context.developerDescription(
            summary: developerSummary,
            nextStep: nextStep
        )
    }

    private var developerSummary: String {
        // Developer-facing, intentionally not localized.
        switch reason {
        case "attestation_not_enabled":
            return "App attestation failed: app attestation is not enabled for this Stripe account."
        case "app_not_registered":
            return "App attestation failed: this app is not registered as a trusted application."
        case "attestation_data_missing":
            return "App attestation failed: attestation data is missing or incomplete."
        case "ios_app_id_mismatch":
            return "App attestation failed: the app identifier does not match the identifier registered for this Stripe account."
        case "ios_assertion_validation_failed":
            return "App attestation failed: the App Attest assertion could not be validated."
        case "ios_environment_mismatch":
            return "App attestation failed: the App Attest environment does not match this Stripe mode."
        case "ios_attestation_validation_failed":
            return "App attestation failed: the App Attest attestation could not be validated."
        default:
            return apiErrorMessage ?? "App attestation failed."
        }
    }

    private var nextStep: String {
        // Developer-facing, intentionally not localized.
        switch reason {
        case "attestation_not_enabled":
            return "Contact Stripe to enable app attestation for this account and mode, then retry the Onramp flow."
        case "app_not_registered":
            return "Register this app's bundle ID or package name as a trusted application with Stripe, then retry the Onramp flow."
        case "attestation_data_missing":
            return "Make sure all required app attestation fields are sent with the request, then retry the Onramp flow."
        case "ios_app_id_mismatch":
            return "Use the iOS bundle ID registered for this Stripe account, then retry the Onramp flow."
        case "ios_assertion_validation_failed":
            return "Request a new challenge, generate a new App Attest assertion, and retry the Onramp flow."
        case "ios_environment_mismatch":
            return "Check the App Attest entitlement for this build and Stripe mode, then retry the Onramp flow."
        case "ios_attestation_validation_failed":
            return "Generate a new App Attest attestation and retry the Onramp flow. If the issue persists, check your app attestation configuration."
        default:
            return apiErrorMessage ?? "Inspect the preserved Stripe API error for details and retry after correcting the app attestation configuration."
        }
    }
}

/// Details from an uncategorized backend API error, enriched with SDK-local diagnostic context.
public struct UncategorizedAPIError: APIErrorContextProviding {

    /// Shared API error context used to expose diagnostics and build developer-facing messages.
    let context: APIErrorContext

    /// Creates an uncategorized API error from shared API error context.
    ///
    /// - Parameter context: Shared API error context used to expose diagnostics.
    init(context: APIErrorContext) {
        self.context = context
    }

    // MARK: - LocalizedError

    public var errorDescription: String? {
        return userFacingMessage
    }

    // MARK: - CustomDebugStringConvertible

    public var debugDescription: String {
        return developerDescription
    }

    // MARK: - UncategorizedAPIError

    /// A localized message that can be shown to the app user.
    public var userFacingMessage: String {
        return apiUserMessage ?? underlyingError.localizedDescription
    }

    /// A developer-facing description with diagnostic details and suggested next steps.
    public var developerDescription: String {
        return context.developerDescription(
            summary: apiErrorMessage ?? underlyingError.localizedDescription,
            nextStep: apiUserMessage ?? underlyingError.localizedDescription
        )
    }
}

/// A type that exposes shared API error context.
protocol APIErrorContextProviding: LocalizedError, CustomDebugStringConvertible {

    /// Shared API error context used to expose diagnostics and build developer-facing messages.
    var context: APIErrorContext { get }
}

/// Contains the common properties of all API error types.
struct APIErrorContext {

    /// The backend `reason` value associated with this error, if one is available.
    let reason: String?

    /// The SDK operation that was running when this error occurred.
    let operation: String

    /// The bundle identifier for the app using the SDK, if one is available.
    let appIdentifier: String?

    /// The Stripe mode associated with this error, if it can be determined.
    let mode: String?

    /// The Stripe iOS SDK version.
    let sdkVersion: String

    /// The backend API error code associated with this error, if one is available.
    let apiErrorCode: String?

    /// The backend API error type associated with this error, if one is available.
    let apiErrorType: String?

    /// The backend developer-facing API error message associated with this error, if one is available.
    let apiErrorMessage: String?

    /// The backend user-facing API error message associated with this error, if one is available.
    let apiUserMessage: String?

    /// A URL to documentation for this error, if one is available.
    let docURL: String?

    /// The original error that was mapped to this error.
    let underlyingError: Swift.Error

    /// The Stripe API request ID associated with this error, if one is available.
    var requestID: String? {
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
                "  \(docURL)",
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

/// Default protocol implementation to surface values from the underlying `APIErrorContext`.
extension APIErrorContextProviding {

    /// The backend `reason` value associated with this error, if one is available.
    public var reason: String? {
        return context.reason
    }

    /// The SDK operation that was running when this error occurred.
    public var operation: String {
        return context.operation
    }

    /// The bundle identifier for the app using the SDK, if one is available.
    public var appIdentifier: String? {
        return context.appIdentifier
    }

    /// The Stripe mode associated with this error, if it can be determined.
    public var mode: String? {
        return context.mode
    }

    /// The Stripe iOS SDK version.
    public var sdkVersion: String {
        return context.sdkVersion
    }

    /// The Stripe API request ID associated with this error, if one is available.
    public var requestID: String? {
        return context.requestID
    }

    /// The backend API error code associated with this error, if one is available.
    public var apiErrorCode: String? {
        return context.apiErrorCode
    }

    /// The backend API error type associated with this error, if one is available.
    public var apiErrorType: String? {
        return context.apiErrorType
    }

    /// The backend developer-facing API error message associated with this error, if one is available.
    public var apiErrorMessage: String? {
        return context.apiErrorMessage
    }

    /// The backend user-facing API error message associated with this error, if one is available.
    public var apiUserMessage: String? {
        return context.apiUserMessage
    }

    /// A URL to documentation for this error, if one is available.
    public var docURL: String? {
        return context.docURL
    }

    /// The original error that was mapped to this error.
    public var underlyingError: Swift.Error {
        return context.underlyingError
    }
}
