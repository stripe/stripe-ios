//
//  CryptoOnrampCoordinator+Error.swift
//  StripeCryptoOnramp
//
//  Created by Mat Schmid on 9/22/25.
//

import Foundation

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

        /// The wallet address is not registered with the current Link account.
        case walletNotRegistered

        /// The wallet network is not supported for ownership verification.
        case unsupportedWalletNetwork

        /// The wallet ownership challenge has expired. Request a new challenge via `getWalletOwnershipChallenge`.
        case walletOwnershipChallengeExpired

        /// The wallet ownership challenge is invalid or has already been used.
        case invalidWalletOwnershipChallenge

        /// The provided signature is invalid for the wallet ownership challenge.
        case invalidWalletOwnershipSignature

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
            case .walletNotRegistered:
                return "The wallet address is not registered with the current Link account."
            case .unsupportedWalletNetwork:
                return "The wallet network is not supported for ownership verification."
            case .walletOwnershipChallengeExpired:
                return "The wallet ownership challenge has expired. Please request a new challenge."
            case .invalidWalletOwnershipChallenge:
                return "The wallet ownership challenge is invalid or has already been used."
            case .invalidWalletOwnershipSignature:
                return "The provided signature is invalid for the wallet ownership challenge."
            }
        }
    }
}
