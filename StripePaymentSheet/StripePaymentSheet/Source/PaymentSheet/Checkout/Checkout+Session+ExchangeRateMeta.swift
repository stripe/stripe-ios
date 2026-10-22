//
//  Checkout+Session+ExchangeRateMeta.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 3/19/26.
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

import Foundation

extension CheckoutController.Session {
    /// Currency identifiers and localized disclosure text returned by CheckoutClient.
    struct ExchangeRateMeta {
        let integrationCurrency: String
        let localizedCurrency: String
        let caption: String?
        let details: String?
        let integrationCaption: String?
    }
}
