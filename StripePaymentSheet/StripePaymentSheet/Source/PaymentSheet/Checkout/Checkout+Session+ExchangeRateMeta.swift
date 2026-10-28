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
        /// The merchant's currency (e.g. "usd").
        let integrationCurrency: String
        /// The customer's local currency (e.g. "gbp").
        let localizedCurrency: String
        /// Server-localized caption for the local currency, or nil if its disclosure is absent.
        /// For example: "1 USD = 0.9234 EUR (includes 2% conversion fee)".
        let caption: String?
        /// Server-localized conversion fee details, when the disclosure calls for them.
        /// For example: "This rate includes a 2% fee to guarantee the exchange rate during checkout."
        let details: String?
        /// Server-localized caption for the merchant's currency, or nil if its disclosure is absent.
        /// For example: "Exchange rate and fees of your bank may apply."
        let integrationCaption: String?
    }
}
