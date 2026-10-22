//
//  PaymentPagesAPIResponse+ExchangeRateMeta.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 3/19/26.
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

import Foundation

extension CheckoutController.Session {
    /// Exchange rate metadata for adaptive pricing in a Checkout Session.
    struct ExchangeRateMeta {
        /// The exchange rate as a string (e.g. "0.776917").
        let exchangeRate: String?
        /// The merchant's currency (e.g. "usd").
        let integrationCurrency: String
        /// The customer's local currency (e.g. "gbp").
        let localizedCurrency: String
        /// The conversion markup in basis points (e.g. 400), if provided.
        let conversionMarkupBps: Int?
        let caption: String?
        let details: String?
        let integrationCaption: String?

        init(
            exchangeRate: String? = nil,
            integrationCurrency: String,
            localizedCurrency: String,
            conversionMarkupBps: Int? = nil,
            caption: String? = nil,
            details: String? = nil,
            integrationCaption: String? = nil
        ) {
            self.exchangeRate = exchangeRate
            self.integrationCurrency = integrationCurrency
            self.localizedCurrency = localizedCurrency
            self.conversionMarkupBps = conversionMarkupBps
            self.caption = caption
            self.details = details
            self.integrationCaption = integrationCaption
        }
    }
}
