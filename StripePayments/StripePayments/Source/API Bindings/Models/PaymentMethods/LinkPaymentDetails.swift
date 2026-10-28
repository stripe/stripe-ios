//
//  LinkPaymentDetails.swift
//  StripePayments
//
//  Created by Till Hellmund on 4/21/25.
//

import Foundation

@_spi(InternalOnlyAPI) @frozen public enum LinkPaymentDetails {
    case card(Card)
    case bankAccount(BankDetails)
    case generic(Generic)

    @_spi(InternalOnlyAPI) public struct Card {
        @_spi(InternalOnlyAPI) public let id: String
        @_spi(InternalOnlyAPI) public let displayName: String?
        @_spi(InternalOnlyAPI) public let expMonth: Int
        @_spi(InternalOnlyAPI) public let expYear: Int
        @_spi(InternalOnlyAPI) public let last4: String
        @_spi(InternalOnlyAPI) public let brand: STPCardBrand

        @_spi(InternalOnlyAPI) public init(
            id: String,
            displayName: String?,
            expMonth: Int,
            expYear: Int,
            last4: String,
            brand: STPCardBrand
        ) {
            self.id = id
            self.displayName = displayName
            self.expMonth = expMonth
            self.expYear = expYear
            self.last4 = last4
            self.brand = brand
        }
    }

    @_spi(InternalOnlyAPI) public struct BankDetails {
        @_spi(InternalOnlyAPI) public let id: String
        @_spi(InternalOnlyAPI) public let bankName: String
        @_spi(InternalOnlyAPI) public let last4: String

        @_spi(InternalOnlyAPI) public init(
            id: String,
            bankName: String,
            last4: String
        ) {
            self.id = id
            self.bankName = bankName
            self.last4 = last4
        }
    }

    @_spi(InternalOnlyAPI) public struct Generic {
        @_spi(InternalOnlyAPI) public let id: String
        @_spi(InternalOnlyAPI) public let label: String
        @_spi(InternalOnlyAPI) public let sublabel: String?

        @_spi(InternalOnlyAPI) public init(
            id: String,
            label: String,
            sublabel: String?
        ) {
            self.id = id
            self.label = label
            self.sublabel = sublabel
        }

        @_spi(InternalOnlyAPI) public var formattedDisplayText: String {
            return [label, sublabel]
                .compactMap { $0 }
                .filter { !$0.isEmpty }
                .joined(separator: " ")
        }
    }

    @_spi(InternalOnlyAPI) public var id: String {
        switch self {
        case .card(let card):
            return card.id
        case .bankAccount(let bankDetails):
            return bankDetails.id
        case .generic(let genericDetails):
            return genericDetails.id
        }
    }

    @_spi(InternalOnlyAPI) public var label: String {
        switch self {
        case .card(let cardDetails):
            return cardDetails.displayName ?? formattedLast4
        case .bankAccount(let bankAccountDetails):
            return bankAccountDetails.bankName
        case .generic(let genericDetails):
            return genericDetails.label
        }
    }

    @_spi(InternalOnlyAPI) public var sublabel: String? {
        switch self {
        case .card(let cardDetails):
            return cardDetails.displayName != nil ? formattedLast4 : nil
        case .bankAccount:
            return formattedLast4
        case .generic(let genericDetails):
            return genericDetails.sublabel
        }
    }

    @_spi(InternalOnlyAPI) public var formattedLast4: String {
        switch self {
        case .card(let cardDetails):
            return "•••• \(cardDetails.last4)"
        case .bankAccount(let bankAccountDetails):
            return "••••\(bankAccountDetails.last4)"
        case .generic(let genericDetails):
            return genericDetails.formattedDisplayText
        }
    }
}
