//
//  STPCheckoutSessionExchangeRateMeta.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 3/19/26.
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

import Foundation

/// Exchange rate metadata for adaptive pricing in a CheckoutSession.
@_spi(STP) public struct STPCheckoutSessionExchangeRateMeta: Equatable {
    /// The identifier for this exchange rate.
    public let id: String
    /// The currency being purchased (e.g. "gbp").
    public let buyCurrency: String
    /// The currency being sold (e.g. "usd").
    public let sellCurrency: String
    /// The exchange rate as a string (e.g. "0.776917").
    public let exchangeRate: String
    /// The merchant's currency (e.g. "usd").
    public let integrationCurrency: String
    /// The customer's local currency (e.g. "gbp").
    public let localizedCurrency: String
    /// The conversion markup in basis points (e.g. 400).
    public let conversionMarkupBps: Int

    static func decodedObject(from dict: [AnyHashable: Any]?) -> STPCheckoutSessionExchangeRateMeta? {
        guard let adaptivePricingInfo = dict?["adaptive_pricing_info"] as? [AnyHashable: Any],
              let activePresentmentCurrency = adaptivePricingInfo["active_presentment_currency"] as? String,
              let sellCurrency = adaptivePricingInfo["integration_currency"] as? String,
              let localCurrencyOptions = adaptivePricingInfo["local_currency_options"] as? [[AnyHashable: Any]] else {
            return nil
        }

        let selectedOption: [AnyHashable: Any]? =
            localCurrencyOptions.first(where: { ($0["currency"] as? String)?.lowercased() == activePresentmentCurrency.lowercased() })
            ?? localCurrencyOptions.first
        guard let selectedOption else {
            return nil
        }

        let buyCurrency = (selectedOption["currency"] as? String) ?? activePresentmentCurrency

        return decode(
            buyCurrency: buyCurrency,
            sellCurrency: sellCurrency,
            localCurrencyOption: selectedOption
        )
    }

    private static func decode(
        buyCurrency: String,
        sellCurrency: String,
        localCurrencyOption: [AnyHashable: Any]
    ) -> STPCheckoutSessionExchangeRateMeta? {
        guard let localizedCurrency = localCurrencyOption["currency"] as? String,
              let exchangeRate = localCurrencyOption["presentment_exchange_rate"] as? String,
              let conversionMarkupBps = localCurrencyOption["conversion_markup_bps"] as? Int else {
            return nil
        }
        let id = "\(sellCurrency.lowercased())_to_\(buyCurrency.lowercased())"
        return STPCheckoutSessionExchangeRateMeta(
            id: id,
            buyCurrency: buyCurrency,
            sellCurrency: sellCurrency,
            exchangeRate: exchangeRate,
            integrationCurrency: sellCurrency,
            localizedCurrency: localizedCurrency,
            conversionMarkupBps: conversionMarkupBps
        )
    }
}
