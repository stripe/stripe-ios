//
//  WalletOwnershipChallengeRequest.swift
//  StripeCryptoOnramp
//
//  Created by Michael Liberatore on 6/17/26.
//

import Foundation

/// Encodable model passed to the `/v1/crypto/internal/wallet_ownership_challenge` endpoint.
struct WalletOwnershipChallengeRequest: Encodable {

    /// The registered wallet address to verify.
    let walletAddress: String

    /// The crypto network for the wallet address.
    let network: CryptoNetwork

    /// Contains credentials required to make the request.
    let credentials: Credentials

    /// Creates a new `WalletOwnershipChallengeRequest` instance.
    /// - Parameters:
    ///   - walletAddress: The registered wallet address to verify.
    ///   - network: The crypto network for the wallet address.
    ///   - consumerSessionClientSecret: Contains credentials required to make the request.
    init(walletAddress: String, network: CryptoNetwork, consumerSessionClientSecret: String) {
        self.walletAddress = walletAddress
        self.network = network
        self.credentials = Credentials(consumerSessionClientSecret: consumerSessionClientSecret)
    }

    // MARK: - Encodable

    private enum CodingKeys: String, CodingKey {
        case walletAddress = "wallet_address"
        case network
        case credentials
    }
}
