//
//  OnrampBankAccountDetails.swift
//  StripeCryptoOnramp
//

/// A snapshot of the selected bank account at payment method collection time.
@_spi(CryptoOnrampAlpha)
public struct OnrampBankAccountDetails {
    /// The last four digits of the bank account, when available.
    public let last4: String?
}
