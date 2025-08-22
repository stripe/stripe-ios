//
//  CryptoNetwork.swift
//  StripeCryptoOnramp
//
//  Created by Mat Schmid on 8/6/25.
//

import Foundation

/// Supported crypto networks for wallet address registration.
@_spi(CryptoOnrampSDKPreview)
public enum CryptoNetwork: String, Codable, CaseIterable {
    case bitcoin = "bitcoin"
    case ethereum = "ethereum"
    case solana = "solana"
    case polygon = "polygon"
    case stellar = "stellar"
    case avalanche = "avalanche"
    case base = "base"
    case aptos = "aptos"
    case optimism = "optimism"
    case worldchain = "worldchain"
    case xrpl = "xrpl"
}
