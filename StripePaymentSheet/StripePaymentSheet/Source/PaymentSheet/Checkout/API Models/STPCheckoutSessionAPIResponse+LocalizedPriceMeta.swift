//
//  STPCheckoutSessionLocalizedPriceMeta.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 3/19/26.
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

import Foundation

/// A localized price option for adaptive pricing in a CheckoutSession.
struct STPCheckoutSessionLocalizedPriceMeta: Equatable {
    /// The identifier for this localized price (e.g. "usd").
    public let id: String
    /// The three-letter ISO currency code (e.g. "usd").
    public let currency: String
    /// The total amount in the smallest currency unit (e.g. 12000 for $120.00).
    public let total: Int

    static func localizedPricesMetas(from dict: [AnyHashable: Any]?) -> [STPCheckoutSessionLocalizedPriceMeta] {
        guard let adaptivePricingInfo = dict?["adaptive_pricing_info"] as? [AnyHashable: Any],
              let localCurrencyOptions = adaptivePricingInfo["local_currency_options"] as? [[AnyHashable: Any]] else {
            return []
        }
        var metas = localCurrencyOptions.compactMap { decode(from: $0) }

        // Always include the integration currency as an option
        if let integrationCurrency = adaptivePricingInfo["integration_currency"] as? String,
           let integrationAmount = adaptivePricingInfo["integration_amount"] as? Int {
            let integrationMeta = STPCheckoutSessionLocalizedPriceMeta(
                id: integrationCurrency,
                currency: integrationCurrency,
                total: integrationAmount
            )
            // Only add if it's not already in the list (in case local_currency_options somehow includes it)
            if !metas.contains(where: { $0.currency.lowercased() == integrationCurrency.lowercased() }) {
                metas.append(integrationMeta)
            }
        }

        return metas
    }

    private static func decode(from dict: [AnyHashable: Any]) -> STPCheckoutSessionLocalizedPriceMeta? {
        guard let currency = dict["currency"] as? String,
              let amount = dict["amount"] as? Int else {
            return nil
        }
        // local_currency_options no longer includes a dedicated id, so currency is the stable identifier.
        return STPCheckoutSessionLocalizedPriceMeta(id: currency, currency: currency, total: amount)
    }
}
