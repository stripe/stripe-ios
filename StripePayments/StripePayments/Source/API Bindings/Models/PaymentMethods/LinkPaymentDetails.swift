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
        @_spi(STP) public let id: String
        @_spi(STP) public let expMonth: Int
        @_spi(STP) public let expYear: Int
        @_spi(STP) public let last4: String
        @_spi(STP) public let brand: STPCardBrand

        @_spi(STP) public init(
            id: String,
            expMonth: Int,
            expYear: Int,
            last4: String,
            brand: STPCardBrand
        ) {
            self.id = id
            self.expMonth = expMonth
            self.expYear = expYear
            self.last4 = last4
            self.brand = brand
        }
    }

    @_spi(STP) public struct BankDetails {
        @_spi(STP) public let id: String
        @_spi(STP) public let bankIconCode: String?
        @_spi(STP) public let bankName: String
        @_spi(STP) public let last4: String

        @_spi(STP) public init(
            id: String,
            bankIconCode: String?,
            bankName: String,
            last4: String
        ) {
            self.id = id
            self.bankIconCode = bankIconCode
            self.bankName = bankName
            self.last4 = last4
        }
    }

    @_spi(STP) public var id: String {
        switch self {
        case .card(let card):
            return card.id
        case .bankAccount(let bankDetails):
            return bankDetails.id
        }
    }
}
