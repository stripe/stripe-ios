//
//  Address.swift
//  StripeCryptoOnramp
//
//  Created by Michael Liberatore on 8/11/25.
//

import Foundation
@_spi(STP) import StripePayments
@_spi(STP) import StripePaymentSheet

/// Represents an address used with `KYCInfo`.
@_spi(STP)
public struct Address: Equatable {

    /// City, district, suburb, town, or village.
    public var city: String?

    /// Two-letter country code (ISO 3166-1 alpha-2).
    public var country: String?

    /// Address line 1 (e.g., street, PO Box, or company name).
    public var line1: String?

    /// Address line 2 (e.g., apartment, suite, unit, or building).
    public var line2: String?

    /// ZIP or postal code.
    public var postalCode: String?

    /// State, county, province, or region.
    public var state: String?

    /// Initializes an Address
    /// - Parameters:
    ///   - city: City, district, suburb, town, or village.
    ///   - country: Two-letter country code (ISO 3166-1 alpha-2).
    ///   - line1: Address line 1 (e.g., street, PO Box, or company name).
    ///   - line2: Address line 2 (e.g., apartment, suite, unit, or building).
    ///   - postalCode: ZIP or postal code.
    ///   - state: State, county, province, or region.
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

    /// Initializes an `Address` using an `STPAddress` instance
    /// - Parameter address: The address from which to generate the new instance.
    /// - Note: `address.name` is unused in the conversion.
    public init(address: STPAddress) {
        city = address.city
        country = address.country
        line1 = address.line1
        line2 = address.line2
        postalCode = address.postalCode
        state = address.state
    }

    /// Initializes an `Address` using a `PaymentSheet.Address`.
    /// - Parameter address: The address from which to generate the new instance.
    public init(address: PaymentSheet.Address) {
        city = address.city
        country = address.country
        line1 = address.line1
        line2 = address.line2
        postalCode = address.postalCode
        state = address.state
    }

    /// Initializes an `Address` using a `AddressViewController.AddressDetails.Address`.
    /// - Parameter address: The address from which to generate the new instance.
    public init(address: AddressViewController.AddressDetails.Address) {
        city = address.city
        country = address.country
        line1 = address.line1
        line2 = address.line2
        postalCode = address.postalCode
        state = address.state
    }
}
