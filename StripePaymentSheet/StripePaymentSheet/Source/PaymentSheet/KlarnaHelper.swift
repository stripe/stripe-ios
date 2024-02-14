//
//  KlarnaHelper.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 11/1/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeCore

/// Helper struct that holds some Klarna specfic logic around accepted currencies and country restrictions
struct KlarnaHelper {

    /// Klarna can only accept payments to specfic countries based on the currency in the PI
    /// - Parameter currency: the currency on the `PaymentIntent`
    /// - Returns: the list of countries this PI can take payment from for Klarna.
    static func availableCountries(currency: String) -> [String] {
//        let currencyToCountry = [
//            "eur": ["AT", "FI", "DE", "NL", "BE", "ES", "IT", "FR", "GR", "IE", "PT"],
//            "dkk": ["DK"],
//            "nok": ["NO"],
//            "sek": ["SE"],
//            "gbp": ["GB"],
//            "usd": ["US"],
//            "aud": ["AU"],
//            "cad": ["CA"],
//            "czk": ["CZ"],
//            "nzd": ["NZ"],
//            "pln": ["PL"],
//            "chf": ["CH"],
//        ]
        let currencyToCountry = KLARNA_COUNTRIES_BY_CURRENCY
        return currencyToCountry[currency.lowercased()] ?? []
    }

    /// Klarna only accepts "Buy Now" from certain countries
    /// Determines if Klarna accepts "Buy Now" from `locale`
    /// - Returns: True if Klarna supports buy now in `locale`
    static func canBuyNow(locale: Locale = Locale.current) -> Bool {
        // A list of countries Klarna supports "buy now" from
        // https://site-admin.stripe.com/docs/payments/klarna#payment-options
        let buyNowAvailable = ["AT", "BE", "DE", "IT", "NL", "ES", "SE", "CA", "AU", "PL", "PT", "CH"]
        return buyNowAvailable.contains(locale.stp_regionCode?.uppercased() ?? "US")
    }

// Hastily ported over (Start)
    static let KLARNA_COUNTRIES_BY_CURRENCY: [String: [String]] = [
      "cad": ["CA"],
      "eur": ["AT", "FI", "DE", "NL", "BE", "ES", "IE", "IT", "FR", "PT", "GR"],
      "chf": ["CH"],
      "dkk": ["DK"],
      "nok": ["NO"],
      "sek": ["SE"],
      "gbp": ["GB"],
      "usd": ["US"],
      "aud": ["AU"],
      "nzd": ["NZ"],
      "czk": ["CZ"],
      "pln": ["PL"],
    ]

    static func validKlarnaCountriesForMerchantCountry(merchantCountry: String) -> [String] {
      guard let merchantRegion = KLARNA_MERCHANT_COUNTRIES_BY_REGION.first(where: { $0.value.contains(merchantCountry) }) else {
        return []
      }
      guard let countries = KLARNA_BUYER_COUNTRIES_BY_REGION[merchantRegion.key] else {
        return []
      }
      return countries
    }

    static let KLARNA_BUYER_COUNTRIES_BY_REGION: [String: [String]] = [
      "US": ["US"],
      "CA": ["CA"],
      "EU": ["AT", "FI", "DE", "NL", "BE", "ES", "IE", "IT", "FR", "PT", "GR", "CH", "NO", "SE", "GB", "CZ", "PL"],
      "AU": ["AU"],
      "NZ": ["NZ"]
    ]

    static let KLARNA_MERCHANT_COUNTRIES_BY_REGION: [String: [String]] = [
      "US": ["US"],
      "CA": ["CA"],
      "EU": ["AT", "FI", "DE", "NL", "BE", "ES", "IE", "IT", "FR", "PT", "GR", "CH", "NO", "SE", "GB", "CZ", "PL", "EE", "LV", "LT", "SK", "SI"],
      "AU": ["AU"],
      "NZ": ["NZ"]
    ]
}
