//
//  CryptoConsumerWallet.swift
//  StripeCryptoOnramp
//
//  Created by Michael Liberatore on 6/17/26.
//

import Foundation

/// A registered crypto consumer wallet.
@_spi(CryptoOnrampAlpha)
public struct CryptoConsumerWallet: Decodable, Equatable {

    /// The consumer wallet's unique identifier.
    public let id: String

    /// The registered wallet address.
    public let walletAddress: String

    /// The crypto network for the registered wallet.
    public let network: CryptoNetwork

    /// Whether this wallet has successfully completed ownership verification.
    public let verifiedOwnership: Bool

    // MARK: - Decodable

    private enum CodingKeys: String, CodingKey {
        case id
        case walletAddress = "wallet_address"
        case network
        case verifiedOwnership = "verified_ownership"
    }
}
