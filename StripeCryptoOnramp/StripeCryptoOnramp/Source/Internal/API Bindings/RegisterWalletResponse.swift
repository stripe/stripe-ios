//
//  RegisterWalletResponse.swift
//  StripeCryptoOnramp
//
//  Created by Mat Schmid on 8/6/25.
//

import Foundation

struct RegisterWalletResponse: Codable {

    /// The created crypto wallet's unique identifier.
    let id: String

    /// The wallet's blockchain address.
    let wallet_address: String?

    /// The crypto network for the wallet address.
    let network: String?

    /// Whether the merchant has proven ownership of this wallet address via a signed challenge.
    let verified_ownership: Bool?
}
