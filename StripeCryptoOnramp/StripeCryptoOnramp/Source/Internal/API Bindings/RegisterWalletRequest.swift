//
//  RegisterWalletRequest.swift
//  StripeCryptoOnramp
//
//  Created by Mat Schmid on 8/6/25.
//

import Foundation

/// Encodable model passed to the `/v1/crypto/internal/wallet` endpoint.
struct RegisterWalletRequest: Encodable {
    /// The crypto wallet address to register.
    let walletAddress: String

    /// The crypto network for the wallet address.
    let network: CryptoNetwork

    /// Contains credentials required to make the request.
    let credentials: Credentials

    /// Creates a new `RegisterWalletRequest` instance.
    /// - Parameters:
    ///   - walletAddress: The crypto wallet address to register.
    ///   - network: The crypto network for the wallet address.
    ///   - consumerSessionClientSecret: Contains credentials required to make the request.
    init(walletAddress: String, network: CryptoNetwork, consumerSessionClientSecret: String) {
        self.walletAddress = walletAddress
        self.network = network
        self.credentials = Credentials(consumerSessionClientSecret: consumerSessionClientSecret)
    }
}
