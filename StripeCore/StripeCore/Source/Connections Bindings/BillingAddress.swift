//
//  BillingAddress.swift
//  StripeCore
//
//  Created by Mat Schmid on 2024-10-16.
//

import Foundation

@_spi(STP) public struct BillingAddress: Encodable {
    @_spi(STP) public let name: String?
    @_spi(STP) public let line1: String?
    @_spi(STP) public let line2: String?
    @_spi(STP) public let city: String?
    @_spi(STP) public let state: String?
    @_spi(STP) public let postalCode: String?
    @_spi(STP) public let countryCode: String?

    @_spi(STP) public init(
        name: String?,
        line1: String?,
        line2: String?,
        city: String?,
        state: String?,
        postalCode: String?,
        countryCode: String?
    ) {
        self.name = name
        self.line1 = line1
        self.line2 = line2
        self.city = city
        self.state = state
        self.postalCode = postalCode
        self.countryCode = countryCode
    }

    enum CodingKeys: String, CodingKey {
        case name
        case line1 = "line_1"
        case line2 = "line_2"
        case city = "locality"
        case state = "administrative_area"
        case postalCode = "postal_code"
        case countryCode = "country_code"
    }
}
