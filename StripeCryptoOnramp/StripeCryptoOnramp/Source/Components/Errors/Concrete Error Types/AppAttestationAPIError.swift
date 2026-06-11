//
//  AppAttestationAPIError.swift
//  StripeCryptoOnramp
//
//  Created by Michael Liberatore on 5/28/26.
//

import Foundation
@_spi(STP) import StripeCore

/// Details from an app attestation API error, enriched with SDK-local diagnostic context.
@_spi(CryptoOnrampAlpha)
public struct AppAttestationAPIError: StripeCryptoOnrampAPIError, APIErrorContextProviding {

    /// Shared API error context used to expose diagnostics and build developer-facing messages.
    public let context: APIErrorContext

    /// Creates an app attestation API error from shared API error context.
    ///
    /// - Parameter context: Shared API error context used to expose diagnostics.
    public init(context: APIErrorContext) {
        self.context = context
    }

    // MARK: - StripeCryptoOnrampAPIError

    public var code: String {
        return context.code(fallback: "link_failed_to_attest_request")
    }

    // MARK: - AppAttestationAPIError

    /// A localized message that can be shown to the app user.
    public var userMessage: String {
        if reason == "app_attestation_unavailable" {
            return String.Localized.cryptoOnrampErrorAppAttestationUnavailable
        } else {
            return String.Localized.cryptoOnrampErrorAppAttestationFailed
        }
    }

    /// A developer-facing description with diagnostic details and suggested next steps.
    public var developerMessage: String {
        return StripeCryptoOnrampErrorRenderer.renderAPIErrorDeveloperMessage(
            context: context,
            summary: developerSummary,
            code: code,
            sdkVersions: sdkVersions,
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
        case "app_attestation_unavailable":
            return """
            App attestation unavailable: this app isn't configured to use Stripe Crypto Onramp.

            This usually means app attestation isn't enabled for this Stripe account, or this app isn't registered as a trusted application. Use your iOS bundle ID or Android package name and contact Stripe to enable app attestation or register the app for this account.
            """
        default:
            return apiMessage ?? "App attestation failed."
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
        case "app_attestation_unavailable":
            return "Confirm app attestation is enabled for this Stripe account and that the app identifier is registered as trusted, then call configure again."
        default:
            return "Inspect the preserved Stripe API error for details and retry after correcting the app attestation configuration."
        }
    }
}
