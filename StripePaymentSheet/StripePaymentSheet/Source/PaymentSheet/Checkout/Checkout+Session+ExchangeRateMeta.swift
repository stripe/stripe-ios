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
        let caption: String?
        let details: String?
        let integrationCaption: String?
    }
}
