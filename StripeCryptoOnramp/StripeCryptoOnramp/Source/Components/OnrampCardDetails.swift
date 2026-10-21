//
//  OnrampCardDetails.swift
//  StripeCryptoOnramp
//
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

import StripePayments

/// A bounded summary of the card used to create a crypto payment token.
@_spi(CryptoOnrampAlpha)
public struct OnrampCardDetails {
    /// The card's funding type. Missing or unrecognized funding is `.other`.
    /// Only `.debit` qualifies for a strict debit-only policy. Funding does not prove card ownership.
    public let funding: STPCardFundingType

    /// The card's brand, or `.unknown` when unavailable or unrecognized.
    public let brand: STPCardBrand

    /// The last four digits, when available. These may identify a wallet-tokenized number,
    /// rather than the physical card's number.
    public let last4: String?
}
