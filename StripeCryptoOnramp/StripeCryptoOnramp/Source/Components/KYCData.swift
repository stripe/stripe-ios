//
//  KYCData.swift
//  StripeCryptoOnramp
//
//  Created by Michael Liberatore on 7/30/25.
//

import Foundation
@_spi(STP) import StripePaymentSheet

/// Represents KYC information required for crypto operations.
@_spi(CryptoOnrampSDKPreview)
public struct KYCData: Equatable {

    /// The customer’s first name.
    let firstName: String

    /// The customer’s last name.
    let lastName: String

    /// The number associated with the customer’s id.
    let idNumber: String?

    /// The type of id provided by the customer.
    let idType: IdType?

    /// The address of the customer.
    let address: PaymentSheet.Address

    /// The customer’s date of birth.
    let dateOfBirth: Date

    /// The country in which the customer was born.
    let birthCountry: String?

    /// The city in which the customer was born.
    let birthCity: String?
}

extension KYCData: Encodable {

    // MARK: - Encodable

    private enum CodingKeys: String, CodingKey {
        case firstName = "first_name"
        case lastName = "last_name"
        case idNumber = "id_number"
        case idType = "id_type"
        case line1
        case line2
        case city
        case state
        case zip
        case country
        case birthCountry = "birth_country"
        case birthCity = "birth_city"
        case dob
    }

    private enum DOBKeys: String, CodingKey {
        case day
        case month
        case year
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(firstName, forKey: .firstName)
        try container.encode(lastName, forKey: .lastName)
        try container.encodeIfPresent(idNumber, forKey: .idNumber)
        try container.encodeIfPresent(idType?.rawValue, forKey: .idType)

        try container.encodeIfPresent(address.line1, forKey: .line1)
        try container.encodeIfPresent(address.line2, forKey: .line2)
        try container.encodeIfPresent(address.city, forKey: .city)
        try container.encodeIfPresent(address.state, forKey: .state)
        try container.encodeIfPresent(address.postalCode, forKey: .zip)
        try container.encodeIfPresent(address.country, forKey: .country)

        try container.encodeIfPresent(birthCountry, forKey: .birthCountry)
        try container.encodeIfPresent(birthCity, forKey: .birthCity)

        // TODO: we’ll likely want to refine calendar usage here, as birth date will differ across time zones. Possibly let the client specify day, month, year instead of `Date`?.
        var dobContainer = container.nestedContainer(keyedBy: DOBKeys.self, forKey: .dob)
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day, .month, .year], from: dateOfBirth)
        try dobContainer.encode(components.day, forKey: .day)
        try dobContainer.encode(components.month, forKey: .month)
        try dobContainer.encode(components.year, forKey: .year)
    }
}
