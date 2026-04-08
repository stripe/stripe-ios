//
//  Address.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 3/2/26.
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

import Foundation

@_spi(CheckoutSessionsPreview)
extension Checkout {
    /// An address used with ``updateBillingAddress(_:)`` and ``updateShippingAddress(_:)``.
    public struct Address: Equatable {
        /// Two-letter country code (ISO 3166-1 alpha-2). Always required.
        public let country: String

        /// Address line 1 (e.g., street, PO Box, or company name).
        public let line1: String?

        /// Address line 2 (e.g., apartment, suite, unit, or building).
        public let line2: String?

        /// City, district, suburb, town, or village.
        public let city: String?

        /// State, county, province, or region.
        public let state: String?

        /// ZIP or postal code.
        public let postalCode: String?

        /// Creates an address.
        /// - Parameters:
        ///   - country: Two-letter country code (ISO 3166-1 alpha-2).
        ///   - line1: Address line 1.
        ///   - line2: Address line 2.
        ///   - city: City, district, suburb, town, or village.
        ///   - state: State, county, province, or region.
        ///   - postalCode: ZIP or postal code.
        public init(
            country: String,
            line1: String? = nil,
            line2: String? = nil,
            city: String? = nil,
            state: String? = nil,
            postalCode: String? = nil
        ) {
            self.country = country
            self.line1 = line1
            self.line2 = line2
            self.city = city
            self.state = state
            self.postalCode = postalCode
        }
    }
}
