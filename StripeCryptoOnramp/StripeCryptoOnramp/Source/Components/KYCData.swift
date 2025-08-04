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

    /// Represents the three components (day, month, year) of a birth date.
    public struct DateOfBirth: Encodable, Equatable {

        /// The one- or two-digit day of the month (e.g. 31).
        public let day: Int

        /// The one- or two-digit month of the year (e.g. January = 1, December = 12).
        public let month: Int

        /// The four digit year (e.g. 2025).
        public let year: Int

        /// Creates a new instance of `DateOfBirth` using a `Date` in the specified `calendar`.
        /// - Parameters:
        ///   - date: The date from which to derive the date components.
        ///   - calendar: The calendar to use in determining the date components. Defaults to `Calendar.current`.
        public init(date: Date, calendar: Calendar = .current) {
            day = calendar.component(.day, from: date)
            month = calendar.component(.month, from: date)
            year = calendar.component(.year, from: date)
        }
        
        /// Creates a new instance of `DateOfBirth`.
        /// - Parameters:
        ///   - day: The one- or two-digit day of the month (e.g. 31).
        ///   - month: The one- or two-digit month of the year (e.g. January = 1, December = 12).
        ///   - year: The four digit year (e.g. 2025).
        public init(day: Int, month: Int, year: Int) {
            self.day = day
            self.month = month
            self.year = year
        }
    }

    /// The customer’s first name.
    public let firstName: String

    /// The customer’s last name.
    public let lastName: String

    /// The number associated with the customer’s id.
    public let idNumber: String?

    /// The type of id provided by the customer.
    public let idType: IdType?

    /// The address of the customer.
    public let address: PaymentSheet.Address

    /// The customer’s date of birth.
    public let dateOfBirth: DateOfBirth

    /// The country in which the customer was born.
    public let birthCountry: String?

    /// The city in which the customer was born.
    public let birthCity: String?
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

        try container.encode(dateOfBirth, forKey: .dob)
        try container.encodeIfPresent(birthCountry, forKey: .birthCountry)
        try container.encodeIfPresent(birthCity, forKey: .birthCity)
    }
}
