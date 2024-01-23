//
//  PaymentDetails.swift
//  StripePaymentSheet
//
//  Created by Cameron Sabol on 3/12/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
@_spi(STP) import StripePaymentsUI
import UIKit

typealias ConsumerSessionWithPaymentDetails = (session: ConsumerSession, paymentDetails: [ConsumerPaymentDetails])

/**
 PaymentDetails response for Link accounts
 
 For internal SDK use only
 */
final class ConsumerPaymentDetails: Decodable {
    let stripeID: String
    let details: Details

    // TODO(csabol) : Billing address

    init(stripeID: String,
         details: Details) {
        self.stripeID = stripeID
        self.details = details
    }

    private enum CodingKeys: String, CodingKey {
        case stripeID = "id"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.stripeID = try container.decode(String.self, forKey: .stripeID)
        // The payment details are included in the dictionary, so we pass the whole dict to Details
        self.details = try decoder.singleValueContainer().decode(Details.self)
    }
}

// MARK: - Details
/// :nodoc:
extension ConsumerPaymentDetails {
    enum DetailsType: String, CaseIterable, SafeEnumCodable {
        case card = "CARD"
        case bankAccount = "BANK_ACCOUNT"
        case unparsable = ""
    }

    enum Details: SafeEnumDecodable {
        case card(card: Card)
        case bankAccount(bankAccount: BankAccount)
        case unparsable

        private enum CodingKeys: String, CodingKey {
            case type
            case card = "cardDetails"
            case bankAccount = "bankAccountDetails"
        }

        // Our JSON structure doesn't align with Swift's expected structure for enums with associated values, so we do custom decoding.
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let type = try container.decode(DetailsType.self, forKey: CodingKeys.type)
            switch type {
            case .card:
                self = .card(card: try container.decode(Card.self, forKey: CodingKeys.card))
            case .bankAccount:
                self = .bankAccount(bankAccount: try container.decode(BankAccount.self, forKey: CodingKeys.bankAccount))
            case .unparsable:
                self = .unparsable
            }
        }
    }

    var type: DetailsType {
        switch details {
        case .card:
            return .card
        case .bankAccount:
            return .bankAccount
        case .unparsable:
            return .unparsable
        }
    }
}

// MARK: - Card checks

extension ConsumerPaymentDetails.Details {
    /// For internal SDK use only
    final class CardChecks: Codable {
        enum CVCCheck: String, SafeEnumCodable {
            case pass = "PASS"
            case fail = "FAIL"
            case unchecked = "UNCHECKED"
            case unavailable = "UNAVAILABLE"
            case stateInvalid = "STATE_INVALID"
            // Catch all
            case unparsable = ""
        }

        let cvcCheck: CVCCheck

        init(cvcCheck: CVCCheck) {
            self.cvcCheck = cvcCheck
        }
    }
}

// MARK: - Details.Card
extension ConsumerPaymentDetails.Details {
    final class Card: Codable {
        let brand: String
        let last4: String

        private enum CodingKeys: String, CodingKey {
            case brand
            case last4
        }

        init(brand: String,
             last4: String) {
            self.brand = brand
            self.last4 = last4
        }
    }
}

// MARK: - Details.Card - Helpers
extension ConsumerPaymentDetails.Details.Card {
    var stpBrand: STPCardBrand {
        return STPCard.brand(from: brand)
    }
}

// MARK: - Details.BankAccount
extension ConsumerPaymentDetails.Details {
    final class BankAccount: Codable {
        let iconCode: String?
        let name: String
        let last4: String

        private enum CodingKeys: String, CodingKey {
            case iconCode = "bankIconCode"
            case name = "bankName"
            case last4
        }

        init(iconCode: String?,
             name: String,
             last4: String) {
            self.iconCode = iconCode
            self.name = name
            self.last4 = last4
        }
    }
}

extension ConsumerPaymentDetails {
    var paymentSheetLabel: String {
        switch details {
        case .card(let card):
            return "••••\(card.last4)"
        case .bankAccount(let bank):
            return "••••\(bank.last4)"
        case .unparsable:
            return ""
        }
    }

    var accessibilityDescription: String {
        switch details {
        case .card(let card):
            // TODO(ramont): investigate why this returns optional
            let cardBrandName = STPCardBrandUtilities.stringFrom(card.stpBrand) ?? ""
            let digits = card.last4.map({ String($0) }).joined(separator: ", ")
            return String(
                format: String.Localized.card_brand_ending_in_last_4,
                cardBrandName,
                digits
            )
        case .bankAccount(let bank):
            let digits = bank.last4.map({ String($0) }).joined(separator: ", ")
            return String(
                format: String.Localized.bank_name_account_ending_in_last_4,
                bank.name,
                digits
            )
        case .unparsable:
            return ""
        }
    }

}
