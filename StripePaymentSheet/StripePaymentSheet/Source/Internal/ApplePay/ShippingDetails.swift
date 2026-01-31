//
//  ShippingDetails.swift
//  StripePaymentSheet
//
//  Adapted from StripeApplePay/ShippingDetails.swift
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation

/// Internal shipping details type for Apple Pay context.
/// This replaces the StripeAPI.ShippingDetails from StripeApplePay.
struct ShippingDetails: Equatable {
    init(
        address: Address?,
        name: String?,
        carrier: String? = nil,
        phone: String? = nil,
        trackingNumber: String? = nil
    ) {
        self.address = address
        self.name = name
        self.carrier = carrier
        self.phone = phone
        self.trackingNumber = trackingNumber
    }

    /// Shipping address.
    var address: Address?

    /// Recipient name.
    var name: String?

    /// The delivery service that shipped a physical product, such as Fedex, UPS, USPS, etc.
    var carrier: String?

    /// Recipient phone (including extension).
    var phone: String?

    /// The tracking number for a physical product, obtained from the delivery service.
    var trackingNumber: String?

    struct Address: Equatable {
        init(
            city: String? = nil,
            country: String? = nil,
            line1: String? = nil,
            line2: String? = nil,
            postalCode: String? = nil,
            state: String? = nil
        ) {
            self.city = city
            self.country = country
            self.line1 = line1
            self.line2 = line2
            self.postalCode = postalCode
            self.state = state
        }

        /// City/District/Suburb/Town/Village.
        var city: String?

        /// Two-letter country code (ISO 3166-1 alpha-2).
        var country: String?

        /// Address line 1 (Street address/PO Box/Company name).
        var line1: String?

        /// Address line 2 (Apartment/Suite/Unit/Building).
        var line2: String?

        /// ZIP or postal code.
        var postalCode: String?

        /// State/County/Province/Region.
        var state: String?
    }
}
