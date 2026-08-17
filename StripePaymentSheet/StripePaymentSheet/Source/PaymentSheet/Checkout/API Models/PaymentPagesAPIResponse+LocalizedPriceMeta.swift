//
//  PaymentPagesAPIResponse+LocalizedPriceMeta.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 3/19/26.
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

import Foundation

/// A localized price option for adaptive pricing in a CheckoutSession.
struct STPCheckoutSessionLocalizedPriceMeta: Equatable {
    /// The identifier for this localized price (e.g. "usd").
    let id: String
    /// The three-letter ISO currency code (e.g. "usd").
    let currency: String
    /// The total amount in the smallest currency unit (e.g. 12000 for $120.00).
    let total: Int
}
