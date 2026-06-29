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
        let verifiedOwnership: Bool

        // TODO: remove both `init`s and `CodingKey`s. We won't need these once the demo backend is returning `verified_ownership`.
        init(
            id: String,
            object: String,
            livemode: Bool,
            network: String,
            walletAddress: String,
            verifiedOwnership: Bool = false
        ) {
            self.id = id
            self.object = object
            self.livemode = livemode
            self.network = network
            self.walletAddress = walletAddress
            self.verifiedOwnership = verifiedOwnership
        }

        init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.id = try container.decode(String.self, forKey: .id)
            self.object = try container.decode(String.self, forKey: .object)
            self.livemode = try container.decode(Bool.self, forKey: .livemode)
            self.network = try container.decode(String.self, forKey: .network)
            self.walletAddress = try container.decode(String.self, forKey: .walletAddress)
            self.verifiedOwnership = try container.decodeIfPresent(Bool.self, forKey: .verifiedOwnership) ?? false
        }

        private enum CodingKeys: String, CodingKey {
            case id
            case object
            case livemode
            case network
            case walletAddress
            case verifiedOwnership
        }
    }

    let object: String
    let count: Int
    let data: [Wallet]
}
