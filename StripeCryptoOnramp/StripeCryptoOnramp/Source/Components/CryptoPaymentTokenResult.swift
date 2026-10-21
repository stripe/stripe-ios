//
//  CryptoPaymentTokenResult.swift
//  StripeCryptoOnramp
//
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

import Foundation

/// A crypto payment token and optional details from the payment source used to create it.
@_spi(CryptoOnrampAlpha)
public struct CryptoPaymentTokenResult {
    /// The crypto payment token ID to send to your backend before creating an onramp session.
    public let cryptoPaymentToken: String

    /// Details of the Apple Pay or Link card used to create this token, when available.
    /// This is `nil` for bank accounts and when card data is unavailable.
    public let cardDetails: OnrampCardDetails?

    /// Details of the Link bank account used to create this token, when available.
    /// This is `nil` for cards and when bank-account data is unavailable.
    public let bankAccountDetails: OnrampBankAccountDetails?
}
