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
        @_spi(STP) public let displayName: String?
        @_spi(STP) public let expMonth: Int
        @_spi(STP) public let expYear: Int
        @_spi(STP) public let last4: String
        @_spi(STP) public let brand: STPCardBrand

        @_spi(STP) public init(
            displayName: String?,
            expMonth: Int,
            expYear: Int,
            last4: String,
            brand: STPCardBrand
        ) {
            self.displayName = displayName
            self.expMonth = expMonth
            self.expYear = expYear
            self.last4 = last4
            self.brand = brand
        }
    }

    @_spi(STP) public struct BankDetails {
        @_spi(STP) public let bankName: String
        @_spi(STP) public let last4: String

        @_spi(STP) public init(
            bankName: String,
            last4: String
        ) {
            self.bankName = bankName
            self.last4 = last4
        }
    }

    public var label: String {
        switch self {
        case .card(let cardDetails):
            return cardDetails.displayName ?? "•••• \(cardDetails.last4)"
        case .bankAccount(let bankAccountDetails):
            return bankAccountDetails.bankName
        }
    }

    public var sublabel: String? {
        switch self {
        case .card(let cardDetails):
            return cardDetails.displayName != nil ? "•••• \(cardDetails.last4)" : nil
        case .bankAccount(let bankAccountDetails):
            return "••••\(bankAccountDetails.last4)"
        }
    }

    public var formattedLast4: String {
        switch self {
        case .card(let cardDetails):
            return "•••• \(cardDetails.last4)"
        case .bankAccount(let bankAccountDetails):
            return "••••\(bankAccountDetails.last4)"
        }
    }
}
