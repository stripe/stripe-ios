//
//  KycInfo.swift
//  StripeCryptoOnramp
//
//  Created by Michael Liberatore on 7/30/25.
//

import Foundation
import PassKit
@_spi(STP) import StripePayments

/// Represents KYC information required for crypto operations.
@_spi(CryptoOnrampAlpha)
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

    /// The customer’s first name, if collected.
    public var firstName: String?

    /// The customer’s last name, if collected.
    public var lastName: String?

    /// The number associated with the customer’s id.
    public var idNumber: String?

    /// The type of id provided by the customer.
    public var idType: IdType = .socialSecurityNumber

    /// The address of the customer, if collected.
    public var address: Address?

    /// The customer’s date of birth.
    public var dateOfBirth: DateOfBirth?

    /// Creates a new instance of `KycInfo`.
    /// - Parameters:
    ///   - firstName: The customer’s first name, if collected.
    ///   - lastName: The customer’s last name, if collected.
    ///   - idNumber: The number associated with the customer’s id.
    ///   - address: The address of the customer, if collected.
    ///   - dateOfBirth: The customer’s date of birth.
    public init(
        firstName: String?,
        lastName: String?,
        idNumber: String?,
        address: Address?,
        dateOfBirth: DateOfBirth?
    ) {
        self.firstName = firstName
        self.lastName = lastName
        self.idNumber = idNumber
        self.address = address
        self.dateOfBirth = dateOfBirth
    }
}

extension KycInfo {

    /// Creates a `KycInfo` from Apple Pay billing information.
    /// Returns `nil` if the `PKPayment` does not contain any usable billing name or address fields.
    /// - Parameter payment: The Apple Pay payment whose billing information should be converted.
    init?(payment: PKPayment) {
        guard let billingContact = payment.billingContact else {
            return nil
        }

        let firstName: String? = {
            guard let givenName = billingContact.name?.givenName else {
                return nil
            }

            let trimmedGivenName = givenName.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedGivenName.isEmpty else {
                return nil
            }

            return trimmedGivenName
        }()

        let lastName: String? = {
            guard let familyName = billingContact.name?.familyName else {
                return nil
            }

            let trimmedFamilyName = familyName.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedFamilyName.isEmpty else {
                return nil
            }

            return trimmedFamilyName
        }()

        let address: Address? = {
            guard billingContact.postalAddress != nil else {
                return nil
            }

            let stpAddress = STPAddress(pkContact: billingContact)
            let address = Address(address: stpAddress)
            return address.isEmpty ? nil : address
        }()

        guard firstName != nil || lastName != nil || address != nil else {
            return nil
        }

        self.init(
            firstName: firstName,
            lastName: lastName,
            idNumber: nil,
            address: address,
            dateOfBirth: nil
        )
    }
}
