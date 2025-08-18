//
//  KycInfo.swift
//  StripeCryptoOnramp
//
//  Created by Michael Liberatore on 7/30/25.
//

import Foundation

/// Represents KYC information required for crypto operations.
@_spi(CryptoOnrampSDKPreview)
public struct KycInfo: Equatable {

    /// Represents a fixed date using simple components (day, month, year).
    public struct DateOfBirth: Encodable, Equatable {

        /// The day of birth.
        public let day: Int

        /// The month of birth.
        public let month: Int

        /// The year of birth.
        public let year: Int

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
    public let firstName: String

    /// The customer’s last name.
    public let lastName: String

    /// The number associated with the customer’s id.
    public let idNumber: String

    /// The type of id provided by the customer.
    public let idType: IdType = .socialSecurityNumber

    /// The address of the customer.
    public let address: Address

    /// The customer’s date of birth.
    public let dateOfBirth: DateOfBirth

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
