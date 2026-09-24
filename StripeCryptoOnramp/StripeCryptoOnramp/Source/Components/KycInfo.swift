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
    public var idType: IdType

    /// The address of the customer, if collected.
    public var address: Address?

    /// The customer’s date of birth.
    public var dateOfBirth: DateOfBirth?

    /// The two-letter country code of the customer’s country of birth (ISO 3166-1 alpha-2), if collected. Required for EU customers.
    public var birthCountry: String?

    /// The customer’s city of birth, if collected. Required for EU customers.
    public var birthCity: String?

    /// The two-letter country codes of the customer’s nationalities (ISO 3166-1 alpha-2), if collected. Required for EU customers.
    public var nationalities: [String]?

    /// The customer’s email address, if collected.
    ///
    /// This value is intended for prefilling Link registration or account lookup and is not part of the KYC submission
    /// payload, so it is ignored when attaching KYC info.
    public var email: String?

    /// The customer’s phone number, if collected.
    ///
    /// When this value originates from a wallet such as Apple Pay, it is passed through exactly as the wallet provided
    /// it and is **not** normalized to E.164 (for example, it may look like `(212) 555-1234`). Convert it to E.164
    /// before passing it to `registerLinkUser(email:fullName:phone:country:)`, which throws `invalidPhoneFormat` for
    /// other formats.
    ///
    /// This value is intended for prefilling Link registration or account lookup and is not part of the KYC submission
    /// payload, so it is ignored when attaching KYC info.
    public var phone: String?

    /// Creates a new instance of `KycInfo`.
    /// - Parameters:
    ///   - firstName: The customer’s first name, if collected.
    ///   - lastName: The customer’s last name, if collected.
    ///   - idNumber: The number associated with the customer’s id.
    ///   - idType: The type of id provided by the customer.
    ///   - address: The address of the customer, if collected.
    ///   - dateOfBirth: The customer’s date of birth.
    ///   - birthCountry: The two-letter country code of the customer’s country of birth (ISO 3166-1 alpha-2), if collected. Required for EU customers.
    ///   - birthCity: The customer’s city of birth, if collected. Required for EU customers.
    ///   - nationalities: The two-letter country codes of the customer’s nationalities (ISO 3166-1 alpha-2), if collected. Required for EU customers.
    ///   - email: The customer’s email address, if collected. Used for prefill only.
    ///   - phone: The customer’s phone number, if collected. Used for prefill only, and not normalized to E.164.
    public init(
        firstName: String?,
        lastName: String?,
        idNumber: String?,
        idType: IdType = .socialSecurityNumber,
        address: Address?,
        dateOfBirth: DateOfBirth?,
        birthCountry: String? = nil,
        birthCity: String? = nil,
        nationalities: [String]? = nil,
        email: String? = nil,
        phone: String? = nil
    ) {
        self.firstName = firstName
        self.lastName = lastName
        self.idNumber = idNumber
        self.idType = idType
        self.address = address
        self.dateOfBirth = dateOfBirth
        self.birthCountry = birthCountry
        self.birthCity = birthCity
        self.nationalities = nationalities
        self.email = email
        self.phone = phone
    }
}

extension KycInfo {

    /// Creates a `KycInfo` from Apple Pay billing information.
    /// Returns `nil` if the `PKPayment` does not contain any usable billing name or address fields.
    ///
    /// Email and phone are only returned by Apple Pay when the merchant requests them via the payment request’s
    /// `requiredBillingContactFields` or `requiredShippingContactFields`, and the customer may decline or edit them.
    /// - Parameter payment: The Apple Pay payment whose billing information should be converted.
    init?(payment: PKPayment) {
        let billingContact = payment.billingContact
        let shippingContact = payment.shippingContact

        guard billingContact != nil || shippingContact != nil else {
            return nil
        }

        let firstName = Self.trimmedNonEmptyValue(billingContact?.name?.givenName)
        let lastName = Self.trimmedNonEmptyValue(billingContact?.name?.familyName)

        let address: Address? = {
            guard let billingContact, billingContact.postalAddress != nil else {
                return nil
            }

            let stpAddress = STPAddress(pkContact: billingContact)
            let address = Address(address: stpAddress)
            return address.isEmpty ? nil : address
        }()

        // Apple returns email and phone on whichever contact the merchant requested them for.
        let email = Self.trimmedNonEmptyValue(billingContact?.emailAddress)
            ?? Self.trimmedNonEmptyValue(shippingContact?.emailAddress)

        // Preserved exactly as provided by Apple Pay, which may be display-formatted rather than E.164.
        let phone = Self.trimmedNonEmptyValue(billingContact?.phoneNumber?.stringValue)
            ?? Self.trimmedNonEmptyValue(shippingContact?.phoneNumber?.stringValue)

        guard firstName != nil || lastName != nil || address != nil else {
            return nil
        }

        self.init(
            firstName: firstName,
            lastName: lastName,
            idNumber: nil,
            address: address,
            dateOfBirth: nil,
            email: email,
            phone: phone
        )
    }

    /// Returns the provided value trimmed of surrounding whitespace, or `nil` if it is missing or empty.
    private static func trimmedNonEmptyValue(_ value: String?) -> String? {
        guard let trimmedValue = value?.trimmingCharacters(in: .whitespacesAndNewlines), !trimmedValue.isEmpty else {
            return nil
        }

        return trimmedValue
    }
}
