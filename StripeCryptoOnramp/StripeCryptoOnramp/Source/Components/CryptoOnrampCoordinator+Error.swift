//
//  CryptoOnrampCoordinator+Error.swift
//  StripeCryptoOnramp
//
//  Created by Mat Schmid on 9/22/25.
//

import Foundation
@_spi(STP) import StripeCore

@_spi(CryptoOnrampAlpha)
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
        case appAttestationFailed(AppAttestationAPIError)

        /// A Stripe API error without a more specific Crypto Onramp category.
        case uncategorizedAPIError(UncategorizedAPIError)

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
            case .appAttestationFailed(let error):
                return error.userFacingMessage
            case .uncategorizedAPIError(let error):
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
            case .appAttestationFailed(let error):
                return error.developerDescription
            case .uncategorizedAPIError(let error):
                return error.developerDescription
            }
        }

        /// A URL to documentation for this error, if one is available.
        public var docURL: String? {
            return apiError?.docURL
        }

        /// The backend `reason` value associated with this error, if one is available.
        public var reason: String? {
            return apiError?.reason
        }

        /// The Stripe API request ID associated with this error, if one is available.
        public var requestID: String? {
            return apiError?.requestID
        }

        /// The SDK operation that was running when this error occurred, if one is available.
        public var operation: String? {
            return apiError?.operation
        }

        /// The Stripe mode associated with this error, if it can be determined.
        public var mode: String? {
            return apiError?.mode
        }

        /// The backend API error code associated with this error, if one is available.
        public var apiErrorCode: String? {
            return apiError?.apiErrorCode
        }

        /// The backend API error type associated with this error, if one is available.
        public var apiErrorType: String? {
            return apiError?.apiErrorType
        }

        /// The backend developer-facing API error message associated with this error, if one is available.
        public var apiErrorMessage: String? {
            return apiError?.apiErrorMessage
        }

        /// The original error that was mapped to this error, if one is available.
        public var underlyingError: Swift.Error? {
            return apiError?.underlyingError
        }

        private var apiError: (any APIErrorContextProviding)? {
            switch self {
            case .appAttestationFailed(let error):
                return error
            case .uncategorizedAPIError(let error):
                return error
            default:
                return nil
            }
        }
    }

}

extension CryptoOnrampCoordinator.Error: CustomDebugStringConvertible {

    // MARK: - CustomDebugStringConvertible

    public var debugDescription: String {
        return developerDescription
    }
}
