//
//  LinkPaymentDetails.swift
//  StripePayments
//
//  Created by Till Hellmund on 4/21/25.
//

import Foundation

@_spi(STP) public enum LinkPaymentDetails {
    case card(Card)
    case bankAccount(BankDetails)

    @_spi(STP) public struct Card {
        @_spi(STP) public let expMonth: Int
        @_spi(STP) public let expYear: Int
        @_spi(STP) public let last4: String
        @_spi(STP) public let brand: STPCardBrand

        @_spi(STP) public init(expMonth: Int, expYear: Int, last4: String, brand: STPCardBrand) {
            self.expMonth = expMonth
            self.expYear = expYear
            self.last4 = last4
            self.brand = brand
        }
    }

    @_spi(STP) public struct BankDetails {
        @_spi(STP) public let bankIconCode: String?
        @_spi(STP) public let bankName: String
        @_spi(STP) public let last4: String

        @_spi(STP) public init(bankIconCode: String?, bankName: String, last4: String) {
            self.bankIconCode = bankIconCode
            self.bankName = bankName
            self.last4 = last4
        }
    }
}
