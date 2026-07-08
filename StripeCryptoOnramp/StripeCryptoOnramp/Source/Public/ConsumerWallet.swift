//
//  ConsumerWallet.swift
//  StripeCryptoOnramp
//

import Foundation

/// A registered crypto consumer wallet, returned after wallet registration or
/// ownership verification.
@_spi(CryptoOnrampAlpha)
public struct ConsumerWallet {
    /// The unique identifier for this wallet.
    public let id: String

    /// The wallet's blockchain address.
    public let walletAddress: String

    /// The crypto network for this wallet address.
    public let network: String

    /// Whether the merchant has proven ownership of this wallet address via a
    /// signed challenge. `nil` if ownership verification has not been attempted.
    public let verifiedOwnership: Bool?
}
