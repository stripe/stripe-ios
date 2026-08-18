//
//  PaymentPagesAPIResponse+ExchangeRateMeta.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 3/19/26.
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

import Foundation

/// Exchange rate metadata for adaptive pricing in a CheckoutSession.
struct STPCheckoutSessionExchangeRateMeta: Equatable {
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
    /// The conversion markup in basis points (e.g. 400), if provided.
    public let conversionMarkupBps: Int?
}
