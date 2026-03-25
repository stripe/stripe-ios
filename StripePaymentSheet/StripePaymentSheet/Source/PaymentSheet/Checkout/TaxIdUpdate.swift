//
//  TaxIdUpdate.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 3/2/2026.
//

import Foundation

@_spi(CheckoutSessionsPreview)
extension Checkout {
    /// Parameters for updating the tax ID on a Checkout Session.
    public struct TaxIdUpdate: Sendable {
        /// The type of tax ID (e.g., `"eu_vat"`, `"us_ein"`, `"gb_vat"`).
        public let type: String
        /// The tax ID value (e.g., `"DE123456789"`).
        public let value: String

        public init(type: String, value: String) {
            self.type = type
            self.value = value
        }
    }
}
