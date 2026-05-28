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
    enum Error: StripeCryptoOnrampError {

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

        // MARK: - StripeCryptoOnrampError

        /// A stable code identifying this error.
        public var code: String {
            switch self {
            case .invalidPhoneFormat:
                return "invalid_phone_format"
            case .linkAccountAlreadyExists:
                return "link_account_already_exists"
            case .missingEphemeralKey:
                return "missing_ephemeral_key"
            case .invalidSelectedPaymentSource:
                return "invalid_selected_payment_source"
            case .missingCryptoCustomerID:
                return "missing_crypto_customer_id"
            case .linkAccountNotVerified:
                return "link_account_not_verified"
            case .seamlessSignInTokenInvalid:
                return "seamless_sign_in_token_invalid"
            }
        }

        /// A localized message that can be shown to the app user.
        public var userMessage: String {
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
            }
        }

        /// A developer-facing description with diagnostic details and suggested next steps.
        public var developerMessage: String {
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
            }
        }

        /// A URL to documentation for this error, if one is available.
        public var docURL: URL? {
            return nil
        }

        /// The original error that was mapped to this error, if one is available.
        public var underlyingError: Swift.Error? {
            return nil
        }
    }
}
