//
//  WalletOwnershipChallengeResponse.swift
//  StripeCryptoOnramp
//

import Foundation

struct WalletOwnershipChallengeResponse: Codable {
    let challenge_id: String
    let wallet_address: String
    let network: String
    let message: String
    let expires_at: String
}
