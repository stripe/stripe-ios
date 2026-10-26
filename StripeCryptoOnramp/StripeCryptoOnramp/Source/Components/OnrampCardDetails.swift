//
//  OnrampCardDetails.swift
//  StripeCryptoOnramp
//

@_spi(STP) import StripeApplePay
import StripeCore
import StripePayments

/// A snapshot of the selected card at payment method collection time.
@_spi(CryptoOnrampAlpha)
public struct OnrampCardDetails {
    /// The card's funding type. Only explicit `.debit` indicates a debit card.
    public let funding: STPCardFundingType

    /// The card's brand, or `.unknown` when unavailable.
    public let brand: STPCardBrand

    /// The last four digits, when available. Wallet digits may identify a tokenized number.
    public let last4: String?
}

extension OnrampCardDetails {
    init?(card: StripeAPI.PaymentMethod.Card?) {
        guard let card else {
            return nil
        }
        self.init(
            funding: STPCard.funding(from: card.funding ?? ""),
            brand: STPCard.brand(from: card.brand.rawValue),
            last4: card.last4
        )
    }
}
