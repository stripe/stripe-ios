//
//  WalletOwnershipChallenge.swift
//  StripeCryptoOnramp
//

import Foundation

/// A short-lived challenge issued by Stripe for wallet ownership verification.
/// The merchant's wallet stack should sign the `message` field and submit the
/// signature via `CryptoOnrampCoordinator.submitWalletOwnershipSignature(challengeId:signature:)`.
@_spi(CryptoOnrampAlpha)
public struct WalletOwnershipChallenge {
    /// The unique identifier for this challenge.
    public let challengeId: String

    /// The wallet address this challenge was issued for.
    public let walletAddress: String

    /// The crypto network for the wallet address.
    public let network: String

    /// The opaque message to be signed by the merchant's wallet stack.
    public let message: String

    /// The ISO 8601 timestamp at which this challenge expires.
    public let expiresAt: String
}
