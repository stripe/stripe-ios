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
public struct KYCData: Codable, Equatable {

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
