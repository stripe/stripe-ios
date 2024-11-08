//
//  BillingAddress.swift
//  StripeCore
//
//  Created by Mat Schmid on 2024-10-16.
//

import Foundation

@_spi(STP) public struct BillingAddress: Codable {
    @_spi(STP) public let name: String?
    @_spi(STP) public let line1: String?
    @_spi(STP) public let line2: String?
    @_spi(STP) public let city: String?
    @_spi(STP) public let state: String?
    @_spi(STP) public let postalCode: String?
    @_spi(STP) public let countryCode: String?

    @_spi(STP) public init(
        name: String? = nil,
        line1: String? = nil,
        line2: String? = nil,
        city: String? = nil,
        state: String? = nil,
        postalCode: String? = nil,
        countryCode: String? = nil
    ) {
        self.name = name
        self.line1 = line1
        self.line2 = line2
        self.city = city
        self.state = state
        self.postalCode = postalCode
        self.countryCode = countryCode
    }

    @_spi(STP) public init(from billingDetails: ElementsSessionContext.BillingDetails?) {
        self.init(
            name: billingDetails?.name,
            line1: billingDetails?.address?.line1,
            line2: billingDetails?.address?.line2,
            city: billingDetails?.address?.city,
            state: billingDetails?.address?.state,
            postalCode: billingDetails?.address?.postalCode,
            countryCode: billingDetails?.address?.country
        )
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

    // Custom encoder to only encode non-nil & non-empty properties.
    @_spi(STP) public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfNotEmpty(name, forKey: .name)
        try container.encodeIfNotEmpty(line1, forKey: .line1)
        try container.encodeIfNotEmpty(line2, forKey: .line2)
        try container.encodeIfNotEmpty(city, forKey: .city)
        try container.encodeIfNotEmpty(state, forKey: .state)
        try container.encodeIfNotEmpty(postalCode, forKey: .postalCode)
        try container.encodeIfNotEmpty(countryCode, forKey: .countryCode)
    }
}
