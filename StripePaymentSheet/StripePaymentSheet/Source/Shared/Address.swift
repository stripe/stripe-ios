//
//  Address.swift
//  StripePaymentSheet
//
//  Created by David Estes on 3/10/25.
//

import Foundation

/// An address.
public struct Address: Equatable {
    /// City, district, suburb, town, or village.
    /// - Note: The value set is displayed in the payment sheet as-is. Depending on the payment method, the customer may be required to edit this value.
    public var city: String?

    /// Two-letter country code (ISO 3166-1 alpha-2).
    public var country: String?

    /// Address line 1 (e.g., street, PO Box, or company name).
    /// - Note: The value set is displayed in the payment sheet as-is. Depending on the payment method, the customer may be required to edit this value.
    public var line1: String?

    /// Address line 2 (e.g., apartment, suite, unit, or building).
    /// - Note: The value set is displayed in the payment sheet as-is. Depending on the payment method, the customer may be required to edit this value.
    public var line2: String?

    /// ZIP or postal code.
    /// - Note: The value set is displayed in the payment sheet as-is. Depending on the payment method, the customer may be required to edit this value.
    public var postalCode: String?

    /// State, county, province, or region.
    /// - Note: The value set is displayed in the payment sheet as-is. Depending on the payment method, the customer may be required to edit this value.
    public var state: String?

    /// Initializes an Address
    public init(
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
}
