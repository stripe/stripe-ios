//
//  BillingAddress.swift
//  StripeCore
//
//  Created by Mat Schmid on 2024-10-16.
//

import Foundation

@_spi(STP) public struct BillingAddress: Encodable {
    let name: String?
    let line1: String?
    let line2: String?
    let city: String?
    let state: String?
    let postalCode: String?
    let countryCode: String?

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
