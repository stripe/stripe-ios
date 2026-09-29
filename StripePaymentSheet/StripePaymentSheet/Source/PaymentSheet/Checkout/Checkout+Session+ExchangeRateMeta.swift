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
        let exchangeRate: String
        /// The merchant's currency (e.g. "usd").
        let integrationCurrency: String
        /// The customer's local currency (e.g. "gbp").
        let localizedCurrency: String
        /// The conversion markup in basis points (e.g. 400), if provided.
        let conversionMarkupBps: Int?
    }
}
