//
//  CryptoOnrampCoordinator+ErrorMapping.swift
//  StripeCryptoOnramp
//
//  Created by Michael Liberatore on 5/26/26.
//

import Foundation
@_spi(STP) import StripeCore

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
        if let stripeError = error as? StripeError,
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
            default:
                return UncategorizedAPIError(
                    context: apiErrorContext(
                        from: error,
                        apiError: apiError,
                        during: operation,
                        apiClient: apiClient,
                        docURL: apiError.docUrl,
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
            context: apiErrorContext(
                from: error,
                apiError: apiError,
                during: operation,
                apiClient: apiClient,
                docURL: apiError.docUrl,
                additionalSDKVersions: additionalSDKVersions
            )
        )
    }

    private static func apiErrorContext(
        from error: Swift.Error,
        apiError: StripeAPIError,
        during operation: CryptoOnrampOperation,
        apiClient: STPAPIClient,
        docURL: URL?,
        additionalSDKVersions: [SDKVersion]
    ) -> APIErrorContext {
        return APIErrorContext(
            reason: apiError.allResponseFields["reason"] as? String,
            operation: operation.rawValue,
            appIdentifier: Bundle.main.bundleIdentifier,
            mode: apiClient.publishableKey.flatMap(Self.publishableKeyMode),
            apiErrorCode: apiError.code,
            apiErrorType: apiErrorType(from: apiError),
            apiErrorMessage: apiError.message,
            apiUserMessage: apiError.allResponseFields["user_message"] as? String,
            docURL: docURL,
            underlyingError: error,
            sdkVersions: [.stripeIOS] + additionalSDKVersions
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
