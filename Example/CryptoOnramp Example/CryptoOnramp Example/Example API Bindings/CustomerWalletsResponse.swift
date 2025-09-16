//
//  CustomerWalletsResponse.swift
//  CryptoOnramp Example
//
//  Created by Michael Liberatore on 8/19/25.
//

import Foundation

struct CustomerWalletsResponse: Decodable, Hashable {
    struct Wallet: Decodable, Hashable, Identifiable {
        let id: String
        let object: String
        let livemode: Bool
        let network: String
        let walletAddress: String
    }

    let object: String
    let count: Int
    let data: [Wallet]
}
