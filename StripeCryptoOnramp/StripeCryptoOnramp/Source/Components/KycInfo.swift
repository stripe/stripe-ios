//
//  KycInfo.swift
//  StripeCryptoOnramp
//
//  Created by Michael Liberatore on 7/30/25.
//

import Foundation

/// Represents KYC information required for crypto operations.
@_spi(STP)
public struct KycInfo: Equatable {

    /// Represents a fixed date using simple components (day, month, year).
    /// For example, March 31st, 1975 would be:
    ///
    /// ```
    /// DateOfBirth(day: 31, month: 3, year: 1975)
    /// ```
    public struct DateOfBirth: Codable, Equatable {

        /// The day of birth.
        public var day: Int

        /// The month of birth.
        public var month: Int

        /// The year of birth.
        public var year: Int

        /// Creates a new `DateOfBirth`.
        /// - Parameters:
        ///   - day: The day of birth.
        ///   - month: The month of birth.
        ///   - year: The year of birth.
        public init(day: Int, month: Int, year: Int) {
            self.day = day
            self.month = month
            self.year = year
        }
    }

    /// The customer’s first name.
    public var firstName: String

    /// The customer’s last name.
    public var lastName: String

    /// The number associated with the customer’s id.
    public var idNumber: String

    /// The type of id provided by the customer.
    public var idType: IdType = .socialSecurityNumber

    /// The address of the customer.
    public var address: Address

    /// The customer’s date of birth.
    public var dateOfBirth: DateOfBirth

    /// Creates a new instance of `KycInfo`.
    /// - Parameters:
    ///   - firstName: The customer’s first name.
    ///   - lastName: The customer’s last name.
    ///   - idNumber: The number associated with the customer’s id.
    ///   - address: The address of the customer.
    ///   - dateOfBirth: The customer’s date of birth.
    public init(
        firstName: String,
        lastName: String,
        idNumber: String,
        address: Address,
        dateOfBirth: DateOfBirth
    ) {
        self.firstName = firstName
        self.lastName = lastName
        self.idNumber = idNumber
        self.address = address
        self.dateOfBirth = dateOfBirth
    }
}
