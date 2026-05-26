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
        case appAttestationFailed(APIErrorDetails)

        /// A Stripe API error without a more specific Crypto Onramp category.
        case uncategorizedAPIError(APIErrorDetails)

        // MARK: - LocalizedError

        public var errorDescription: String? {
            return userFacingMessage
        }

        // MARK: - CryptoOnrampCoordinator.Error

        /// A localized message that can be shown to the app user.
        public var userFacingMessage: String {
            switch self {
            case .invalidPhoneFormat:
                return String.Localized.cryptoOnrampErrorInvalidPhoneFormat
            case .linkAccountAlreadyExists:
                return String.Localized.cryptoOnrampErrorLinkAccountAlreadyExists
            case .missingEphemeralKey:
                return String.Localized.cryptoOnrampErrorMissingEphemeralKey
            case .invalidSelectedPaymentSource:
                return String.Localized.cryptoOnrampErrorInvalidSelectedPaymentSource
            case .missingCryptoCustomerID:
                return String.Localized.cryptoOnrampErrorMissingCryptoCustomerID
            case .linkAccountNotVerified:
                return String.Localized.cryptoOnrampErrorLinkAccountNotVerified
            case .seamlessSignInTokenInvalid:
                return String.Localized.cryptoOnrampErrorSeamlessSignInTokenInvalid
            case .appAttestationFailed(let error),
                 .uncategorizedAPIError(let error):
                return error.userFacingMessage
            }
        }

        /// A developer-facing description with diagnostic details and suggested next steps.
        public var developerDescription: String {
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
            case .appAttestationFailed(let error),
                 .uncategorizedAPIError(let error):
                return error.developerDescription
            }
        }

        /// A URL to documentation for this error, if one is available.
        public var docURL: String? {
            switch self {
            case .appAttestationFailed(let error),
                 .uncategorizedAPIError(let error):
                return error.docURL
            default:
                return nil
            }
        }

        /// The backend `reason` value associated with this error, if one is available.
        public var reason: String? {
            switch self {
            case .appAttestationFailed(let error),
                 .uncategorizedAPIError(let error):
                return error.reason
            default:
                return nil
            }
        }

        /// The Stripe API request ID associated with this error, if one is available.
        public var requestID: String? {
            switch self {
            case .appAttestationFailed(let error),
                 .uncategorizedAPIError(let error):
                return error.requestID
            default:
                return nil
            }
        }

        /// The SDK operation that was running when this error occurred, if one is available.
        public var operation: String? {
            switch self {
            case .appAttestationFailed(let error),
                 .uncategorizedAPIError(let error):
                return error.operation
            default:
                return nil
            }
        }

        /// The Stripe mode associated with this error, if it can be determined.
        public var mode: String? {
            switch self {
            case .appAttestationFailed(let error),
                 .uncategorizedAPIError(let error):
                return error.mode
            default:
                return nil
            }
        }

        /// The backend API error code associated with this error, if one is available.
        public var apiErrorCode: String? {
            switch self {
            case .appAttestationFailed(let error),
                 .uncategorizedAPIError(let error):
                return error.apiErrorCode
            default:
                return nil
            }
        }

        /// The backend API error type associated with this error, if one is available.
        public var apiErrorType: String? {
            switch self {
            case .appAttestationFailed(let error),
                 .uncategorizedAPIError(let error):
                return error.apiErrorType
            default:
                return nil
            }
        }

        /// The backend developer-facing API error message associated with this error, if one is available.
        public var apiErrorMessage: String? {
            switch self {
            case .appAttestationFailed(let error),
                 .uncategorizedAPIError(let error):
                return error.apiErrorMessage
            default:
                return nil
            }
        }

        /// The original error that was mapped to this error, if one is available.
        public var underlyingError: Swift.Error? {
            switch self {
            case .appAttestationFailed(let error),
                 .uncategorizedAPIError(let error):
                return error.underlyingError
            default:
                return nil
            }
        }
    }

    /// Details from a backend API error, enriched with SDK-local diagnostic context.
    struct APIErrorDetails: LocalizedError {

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
        public let docURL: String?

        /// The original error that was mapped to this error.
        public let underlyingError: Swift.Error

        // MARK: - LocalizedError

        public var errorDescription: String? {
            return userFacingMessage
        }

        // MARK: - APIErrorDetails

        /// The Stripe API request ID associated with this error, if one is available.
        public var requestID: String? {
            guard let stripeError = underlyingError as? StripeError,
                  case let .apiError(apiError) = stripeError else {
                return nil
            }
            return apiError.requestID
        }

        /// A localized message that can be shown to the app user.
        public var userFacingMessage: String {
            if isAppAttestationError {
                return String.Localized.cryptoOnrampErrorAppAttestationFailed
            } else if let apiUserMessage {
                return apiUserMessage
            }
            return underlyingError.localizedDescription
        }

        /// A developer-facing description with diagnostic details and suggested next steps.
        public var developerDescription: String {
            let summary = developerSummary
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

        private var developerSummary: String {
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
                if isAppAttestationError {
                    return apiErrorMessage ?? "App attestation failed."
                }
                return apiErrorMessage ?? underlyingError.localizedDescription
            }
        }

        private var nextStep: String {
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

extension CryptoOnrampCoordinator.Error: CustomDebugStringConvertible {

    // MARK: - CustomDebugStringConvertible

    public var debugDescription: String {
        return developerDescription
    }
}

extension CryptoOnrampCoordinator.APIErrorDetails: CustomDebugStringConvertible {

    // MARK: - CustomDebugStringConvertible

    public var debugDescription: String {
        return developerDescription
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
                return Error.uncategorizedAPIError(
                    apiErrorDetails(
                        from: error,
                        apiError: apiError,
                        during: operation,
                        apiClient: apiClient,
                        docURL: apiError.docUrl?.absoluteString
                    )
                )
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
        return Error.appAttestationFailed(
            apiErrorDetails(
                from: error,
                apiError: apiError,
                during: operation,
                apiClient: apiClient,
                docURL: nil
            )
        )
    }

    private static func apiErrorDetails(
        from error: Swift.Error,
        apiError: StripeAPIError,
        during operation: CryptoOnrampOperation,
        apiClient: STPAPIClient,
        docURL: String?
    ) -> APIErrorDetails {
        return APIErrorDetails(
            reason: apiError.allResponseFields["reason"] as? String,
            operation: operation.rawValue,
            appIdentifier: Bundle.main.bundleIdentifier,
            mode: apiClient.publishableKey.flatMap(Self.publishableKeyMode),
            sdkVersion: STPAPIClient.STPSDKVersion,
            apiErrorCode: apiError.code,
            apiErrorType: apiErrorType(from: apiError),
            apiErrorMessage: apiError.message,
            apiUserMessage: apiError.allResponseFields["user_message"] as? String,
            docURL: docURL,
            underlyingError: error
        )
    }

    private static func apiErrorType(from apiError: StripeAPIError) -> String? {
        if let rawType = apiError.allResponseFields["type"] as? String {
            return rawType
        }

        switch apiError.type {
        case .unparsable:
            return nil
        default:
            return apiError.type.rawValue
        }
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
