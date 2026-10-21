//
//  CryptoPaymentTokenResult.swift
//  StripeCryptoOnramp
//
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

import Foundation

/// A crypto payment token and optional card details from the payment source used to create it.
@_spi(CryptoOnrampAlpha)
public struct CryptoPaymentTokenResult {
    /// The crypto payment token ID to send to your backend before creating an onramp session.
    public let cryptoPaymentToken: String

    /// Details of the Apple Pay card used to create this token, when available.
    /// This is `nil` for Link payment methods or when Apple Pay card data is unavailable.
    public let cardDetails: OnrampCardDetails?
}
