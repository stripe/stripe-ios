//
//  CryptoOnrampCoordinator+ErrorMapping.swift
//  StripeCryptoOnramp
//
//  Created by Michael Liberatore on 5/26/26.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripePaymentSheet

extension CryptoOnrampCoordinator {

    /// Maps Stripe API errors into Crypto Onramp errors with user-facing copy and developer diagnostics.
    ///
    /// Non-API errors are returned unchanged so local validation and unrelated SDK failures preserve
    /// their original type and behavior.
    static func mappedError(
        _ error: Swift.Error,
        during operation: CryptoOnrampOperation,
        apiClient: STPAPIClient,
        additionalSDKVersions: [SDKVersion] = []
    ) -> Swift.Error {
        if let integrationError = error as? LinkController.IntegrationError,
           case .missingAppAttestation = integrationError {
            return appAttestationUnavailableError(
                from: error,
                diagnosticContext: diagnosticContext(
                    during: operation,
                    apiClient: apiClient,
                    additionalSDKVersions: additionalSDKVersions
                )
            )
        } else if let stripeError = error as? StripeError,
           case let .apiError(apiError) = stripeError {
            switch apiError.code {
            case "link_failed_to_attest_request":
                return appAttestationError(
                    from: error,
                    apiError: apiError,
                    during: operation,
                    apiClient: apiClient,
                    additionalSDKVersions: additionalSDKVersions
                )
            case "invalid_wallet_ownership_signature":
                return invalidWalletOwnershipSignatureError(
                    from: error,
                    apiError: apiError,
                    during: operation,
                    apiClient: apiClient,
                    additionalSDKVersions: additionalSDKVersions
                )
            case "wallet_ownership_challenge_expired":
                return walletOwnershipChallengeExpiredError(
                    from: error,
                    apiError: apiError,
                    during: operation,
                    apiClient: apiClient,
                    additionalSDKVersions: additionalSDKVersions
                )
            case "invalid_wallet_ownership_challenge":
                return invalidWalletOwnershipChallengeError(
                    from: error,
                    apiError: apiError,
                    during: operation,
                    apiClient: apiClient,
                    additionalSDKVersions: additionalSDKVersions
                )
            case "crypto_onramp_wallet_not_found":
                return cryptoOnrampWalletNotFoundError(
                    from: error,
                    apiError: apiError,
                    during: operation,
                    apiClient: apiClient,
                    additionalSDKVersions: additionalSDKVersions
                )
            case "crypto_onramp_unsupported_network":
                return cryptoOnrampUnsupportedNetworkError(
                    from: error,
                    apiError: apiError,
                    during: operation,
                    apiClient: apiClient,
                    additionalSDKVersions: additionalSDKVersions
                )
            default:
                return UncategorizedAPIError(
                    apiErrorContext: makeAPIErrorContext(
                        from: error,
                        apiError: apiError,
                        docURL: apiError.docUrl
                    ),
                    diagnosticContext: diagnosticContext(
                        during: operation,
                        apiClient: apiClient,
                        additionalSDKVersions: additionalSDKVersions
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
        apiClient: STPAPIClient,
        additionalSDKVersions: [SDKVersion]
    ) -> Swift.Error {
        return AppAttestationAPIError(
            apiErrorContext: makeAPIErrorContext(
                from: error,
                apiError: apiError,
                docURL: apiError.docUrl
            ),
            diagnosticContext: diagnosticContext(
                during: operation,
                apiClient: apiClient,
                additionalSDKVersions: additionalSDKVersions
            )
        )
    }

    private static func invalidWalletOwnershipSignatureError(
        from error: Swift.Error,
        apiError: StripeAPIError,
        during operation: CryptoOnrampOperation,
        apiClient: STPAPIClient,
        additionalSDKVersions: [SDKVersion]
    ) -> Swift.Error {
        return InvalidWalletOwnershipSignatureAPIError(
            apiErrorContext: makeAPIErrorContext(
                from: error,
                apiError: apiError,
                docURL: apiError.docUrl
            ),
            diagnosticContext: diagnosticContext(
                during: operation,
                apiClient: apiClient,
                additionalSDKVersions: additionalSDKVersions
            )
        )
    }

    private static func walletOwnershipChallengeExpiredError(
        from error: Swift.Error,
        apiError: StripeAPIError,
        during operation: CryptoOnrampOperation,
        apiClient: STPAPIClient,
        additionalSDKVersions: [SDKVersion]
    ) -> Swift.Error {
        return WalletOwnershipChallengeExpiredAPIError(
            apiErrorContext: makeAPIErrorContext(
                from: error,
                apiError: apiError,
                docURL: apiError.docUrl
            ),
            diagnosticContext: diagnosticContext(
                during: operation,
                apiClient: apiClient,
                additionalSDKVersions: additionalSDKVersions
            )
        )
    }

    private static func invalidWalletOwnershipChallengeError(
        from error: Swift.Error,
        apiError: StripeAPIError,
        during operation: CryptoOnrampOperation,
        apiClient: STPAPIClient,
        additionalSDKVersions: [SDKVersion]
    ) -> Swift.Error {
        return InvalidWalletOwnershipChallengeAPIError(
            apiErrorContext: makeAPIErrorContext(
                from: error,
                apiError: apiError,
                docURL: apiError.docUrl
            ),
            diagnosticContext: diagnosticContext(
                during: operation,
                apiClient: apiClient,
                additionalSDKVersions: additionalSDKVersions
            )
        )
    }

    private static func cryptoOnrampWalletNotFoundError(
        from error: Swift.Error,
        apiError: StripeAPIError,
        during operation: CryptoOnrampOperation,
        apiClient: STPAPIClient,
        additionalSDKVersions: [SDKVersion]
    ) -> Swift.Error {
        return CryptoOnrampWalletNotFoundAPIError(
            apiErrorContext: makeAPIErrorContext(
                from: error,
                apiError: apiError,
                docURL: apiError.docUrl
            ),
            diagnosticContext: diagnosticContext(
                during: operation,
                apiClient: apiClient,
                additionalSDKVersions: additionalSDKVersions
            )
        )
    }

    private static func cryptoOnrampUnsupportedNetworkError(
        from error: Swift.Error,
        apiError: StripeAPIError,
        during operation: CryptoOnrampOperation,
        apiClient: STPAPIClient,
        additionalSDKVersions: [SDKVersion]
    ) -> Swift.Error {
        return CryptoOnrampUnsupportedNetworkAPIError(
            apiErrorContext: makeAPIErrorContext(
                from: error,
                apiError: apiError,
                docURL: apiError.docUrl
            ),
            diagnosticContext: diagnosticContext(
                during: operation,
                apiClient: apiClient,
                additionalSDKVersions: additionalSDKVersions
            )
        )
    }

    private static func appAttestationUnavailableError(
        from error: Swift.Error,
        diagnosticContext: DiagnosticContext
    ) -> Swift.Error {
        return AppAttestationUnavailableError(
            underlyingError: error,
            diagnosticContext: diagnosticContext
        )
    }

    private static func makeAPIErrorContext(
        from error: Swift.Error,
        apiError: StripeAPIError,
        docURL: URL?
    ) -> APIErrorContext {
        return APIErrorContext(
            reason: apiError.allResponseFields["reason"] as? String,
            apiErrorCode: apiError.code,
            apiErrorType: apiErrorType(from: apiError),
            apiErrorMessage: apiError.message,
            apiUserMessage: apiError.allResponseFields["user_message"] as? String,
            docURL: docURL,
            underlyingError: error
        )
    }

    private static func diagnosticContext(
        during operation: CryptoOnrampOperation,
        apiClient: STPAPIClient,
        additionalSDKVersions: [SDKVersion]
    ) -> DiagnosticContext {
        return DiagnosticContext(
            sdkVersions: [.stripeIOS] + additionalSDKVersions,
            operation: operation.rawValue,
            appPackageName: Bundle.main.bundleIdentifier,
            mode: apiClient.publishableKey.flatMap(Self.publishableKeyMode)
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
