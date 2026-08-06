//
//  WalletOwnershipChallenge.swift
//  StripeCryptoOnramp
//
//  Created by Michael Liberatore on 6/17/26.
//

import Foundation

/// A server-issued challenge for proving ownership of a registered wallet.
@_spi(CryptoOnrampAlpha)
public struct WalletOwnershipChallenge: Decodable, Equatable {

    /// Opaque identifier for this challenge.
    public let challengeId: String

    /// The wallet address bound to this challenge.
    public let walletAddress: String

    /// The crypto network bound to this challenge.
    public let network: CryptoNetwork

    /// Exact opaque message the wallet must sign.
    public let message: String

    /// ISO 8601 timestamp indicating when this challenge expires.
    public let expiresAt: String

    // MARK: - Decodable

    private enum CodingKeys: String, CodingKey {
        case challengeId = "challenge_id"
        case walletAddress = "wallet_address"
        case network
        case message
        case expiresAt = "expires_at"
    }
}
