//
//  KycInfo.swift
//  StripeCryptoOnramp
//
//  Created by Michael Liberatore on 7/30/25.
//

import Foundation
@_spi(STP) import StripePaymentSheet

/// Represents KYC information required for crypto operations.
@_spi(CryptoOnrampSDKPreview)
public struct KycInfo: Equatable {

    /// The customer’s first name.
    public let firstName: String

    /// The customer’s last name.
    public let lastName: String

    /// The number associated with the customer’s id.
    public let idNumber: String?

    /// The type of id provided by the customer.
    public let idType: IdType

    /// The address of the customer.
    public let address: PaymentSheet.Address

    /// The customer’s date of birth.
    public let dateOfBirth: Date

    /// The country in which the customer was born.
    public let birthCountry: String?

    /// The city in which the customer was born.
    public let birthCity: String?

    public init(
        firstName: String,
        lastName: String,
        idNumber: String?,
        idType: IdType = .socialSecurityNumber,
        address: PaymentSheet.Address,
        dateOfBirth: Date,
        birthCountry: String?,
        birthCity: String?
    ) {
        self.firstName = firstName
        self.lastName = lastName
        self.idNumber = idNumber
        self.idType = idType
        self.address = address
        self.dateOfBirth = dateOfBirth
        self.birthCountry = birthCountry
        self.birthCity = birthCity
    }
}
