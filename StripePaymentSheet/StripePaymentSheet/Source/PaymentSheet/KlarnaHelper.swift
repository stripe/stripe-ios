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

    /// Klarna only accepts "Buy Now" from certain countries
    /// Determines if Klarna accepts "Buy Now" from `locale`
    /// - Returns: True if Klarna supports buy now in `locale`
    static func canBuyNow(locale: Locale = Locale.current) -> Bool {
        // A list of countries Klarna supports "buy now" from
        // https://site-admin.stripe.com/docs/payments/klarna#payment-options
        let buyNowAvailable = ["AT", "BE", "DE", "IT", "NL", "ES", "SE", "CA", "AU", "PL", "PT", "CH"]
        return buyNowAvailable.contains(locale.stp_regionCode?.uppercased() ?? "US")
    }
}
