//
//  KlarnaHelper.swift
//  StripeiOS
//
//  Created by Nick Porter on 11/1/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation

/// Helper struct that holds some Klarna specfic logic around accepted currencies and country restrictions
struct KlarnaHelper {
    
    /// Klarna can only accept payments to specfic countries based on the currency in the PI
    /// - Parameter currency: the currency on the `PaymentIntent`
    /// - Returns: the list of countries this PI can take payment from for Klarna.
    static func availableCountries(currency: String) -> [String] {
        let currencyToCountry = [
            "eur": ["AT", "FI", "DE", "NL", "BE", "ES", "IT"],
            "dkk": ["DK"],
            "nok": ["NO"],
            "sek": ["SE"],
            "gbp": ["GB"],
            "usd": ["US"]
        ]
        return currencyToCountry[currency.lowercased()] ?? []
    }
    
    /// Klarna only accepts "Buy Now" from certain countries
    /// Determines if Klarna accepts "Buy Now" from `locale`
    /// - Returns: True if Klarna supports buy now in `locale`
    static func canBuyNow(locale: Locale = Locale.current) -> Bool {
        // A list of countries Klarna supports "buy now" from
        // https://site-admin.stripe.com/docs/payments/klarna#payment-options
        let buyNowAvailable = ["AT", "BE", "DE", "IT", "NL", "ES", "SE"]
        return buyNowAvailable.contains(locale.regionCode?.uppercased() ?? "US")
    }
}
