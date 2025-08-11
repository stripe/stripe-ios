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
    public let idNumber: String

    /// The type of id provided by the customer.
    public let idType: IdType = .socialSecurityNumber

    /// The address of the customer.
    public let address: Address

    /// The customer’s date of birth.
    public let dateOfBirth: Date

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
        dateOfBirth: Date
    ) {
        self.firstName = firstName
        self.lastName = lastName
        self.idNumber = idNumber
        self.address = address
        self.dateOfBirth = dateOfBirth
    }
}
