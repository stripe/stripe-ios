//
//  CryptoOnrampCoordinator+Error.swift
//  StripeCryptoOnramp
//
//  Created by Mat Schmid on 9/22/25.
//

import Foundation
@_spi(STP) import StripeCore

public extension CryptoOnrampCoordinator {
    /// A subset of errors that may be thrown by `CryptoOnrampCoordinator` APIs.
    enum Error: LocalizedError {

        /// Phone number validation failed. Phone number should be in E.164 format (e.g., +12125551234).
        case invalidPhoneFormat

        /// A Link account already exists for the provided email address.
        case linkAccountAlreadyExists

        /// `ephemeralKey` is missing from the response after starting identity verification.
        case missingEphemeralKey

        /// An unexpected error occurred internally. `selectedPaymentSource` was not set to an expected value.
        case invalidSelectedPaymentSource

        /// A crypto customer ID is missing but required.
        case missingCryptoCustomerID

        /// The Link account is not in a verified state.
        case linkAccountNotVerified

        /// The provided sign-in token is invalid for a reason described in the non-localized associated value. Use the `authorize` API to sign in manually.
        case seamlessSignInTokenInvalid(reason: String?)

        /// App attestation failed while processing an SDK operation.
        case appAttestationFailed(ErrorDetails)

        public var errorDescription: String? {
            switch self {
            case .invalidPhoneFormat:
                return "Phone number validation failed. Phone number should be in E.164 format (e.g., +12125551234)."
            case .linkAccountAlreadyExists:
                return "A Link account already exists for the provided email address."
            case .missingEphemeralKey:
                return "Ephemeral key is missing from the response after starting identity verification."
            case .invalidSelectedPaymentSource:
                return "An unexpected error occurred internally. Selected payment source was not set to an expected value."
            case .missingCryptoCustomerID:
                return "A crypto customer ID is missing but required. A crypto customer ID must either be provided to the Crypto Onramp Coordinator in the `create` API, or generated during the onramp flow by verifying a Link account using the `registerLinkUser`, `authenticateUserWithToken`, or `authorize` APIs."
            case .linkAccountNotVerified:
                return "No active Link consumer is available in a verified state."
            case .seamlessSignInTokenInvalid:
                return "An error occurred while automatically signing in to your Link account. Please sign in manually."
            case .appAttestationFailed(let error):
                return error.userFacingMessage
            }
        }

        public var developerDescription: String? {
            switch self {
            case .appAttestationFailed(let error):
                return error.developerDescription
            default:
                return errorDescription
            }
        }
    }

    struct ErrorDetails: LocalizedError {
        public let rawReason: String?
        public let operation: String
        public let appIdentifier: String?
        public let mode: String?
        public let sdkVersion: String
        public let requestID: String?
        public let apiErrorCode: String?
        public let apiErrorMessage: String?
        public let apiUserMessage: String?
        public let docURL: String?
        public let underlyingError: Swift.Error

        public var errorDescription: String? {
            return userFacingMessage
        }

        public var userFacingMessage: String {
            if isAppAttestationError {
                return "This app couldn't be verified. Please try again later."
            } else if let apiUserMessage {
                return apiUserMessage
            }
            return underlyingError.localizedDescription
        }

        public var developerDescription: String? {
            let summary = developerSummary
            let context = [
                "operation: \(operation)",
                appIdentifier.map { "app_id: \($0)" },
                mode.map { "mode: \($0)" },
                rawReason.map { "reason: \($0)" },
                requestID.map { "request_id: \($0)" },
                apiErrorCode.map { "code: \($0)" },
            ].compactMap { $0 }

            return [
                summary,
                "",
                "Context:",
                context.joined(separator: "\n"),
                "",
                "Next step: \(nextStep)",
                docURL.map { "Docs: \($0)" },
                "SDK: stripe-ios@\(sdkVersion)",
            ].compactMap { $0 }.joined(separator: "\n")
        }

        private var developerSummary: String {
            switch rawReason {
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
                if isAppAttestationError {
                    return apiErrorMessage ?? "App attestation failed."
                }
                return apiErrorMessage ?? underlyingError.localizedDescription
            }
        }

        private var nextStep: String {
            switch rawReason {
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
                if isAppAttestationError {
                    return apiErrorMessage ?? "Inspect the preserved Stripe API error for details and retry after correcting the app attestation configuration."
                }
                return apiUserMessage ?? underlyingError.localizedDescription
            }
        }

        private var isAppAttestationError: Bool {
            guard apiErrorCode == "link_failed_to_attest_request" else {
                return false
            }
            return true
        }
    }
}

extension CryptoOnrampCoordinator {
    static func mappedError(
        _ error: Swift.Error,
        during operation: CryptoOnrampOperation,
        apiClient: STPAPIClient
    ) -> Swift.Error {
        if let stripeError = error as? StripeError,
           case let .apiError(apiError) = stripeError {
            switch apiError.code {
            case "link_failed_to_attest_request":
                return appAttestationError(
                    from: error,
                    apiError: apiError,
                    during: operation,
                    apiClient: apiClient
                )
            default:
                return error
            }
        } else {
            return error
        }
    }

    private static func appAttestationError(
        from error: Swift.Error,
        apiError: StripeAPIError,
        during operation: CryptoOnrampOperation,
        apiClient: STPAPIClient
    ) -> Swift.Error {
        let rawReason = apiError.allResponseFields["reason"] as? String
        return Error.appAttestationFailed(
            ErrorDetails(
                rawReason: rawReason,
                operation: operation.rawValue,
                appIdentifier: Bundle.main.bundleIdentifier,
                mode: apiClient.publishableKey.flatMap(Self.publishableKeyMode),
                sdkVersion: STPAPIClient.STPSDKVersion,
                requestID: apiError.requestID,
                apiErrorCode: apiError.code,
                apiErrorMessage: apiError.message,
                apiUserMessage: apiError.allResponseFields["user_message"] as? String,
                docURL: "https://stripe.com/docs/crypto/onramp/app-attestation",
                underlyingError: error
            )
        )
    }

    private static func publishableKeyMode(_ publishableKey: String) -> String? {
        if publishableKey.hasPrefix("pk_live_") {
            return "live"
        } else if publishableKey.hasPrefix("pk_test_") {
            return "test"
        } else {
            return nil
        }
    }
}
