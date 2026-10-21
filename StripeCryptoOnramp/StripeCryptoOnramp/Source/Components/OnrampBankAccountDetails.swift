//
//  OnrampBankAccountDetails.swift
//  StripeCryptoOnramp
//
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

/// A bounded summary of the bank account used to create a crypto payment token.
@_spi(CryptoOnrampAlpha)
public struct OnrampBankAccountDetails {
    /// The last four digits of the bank account, when available.
    /// These digits do not establish mandate validity, settlement speed, ownership, or payment success.
    public let last4: String?
}
