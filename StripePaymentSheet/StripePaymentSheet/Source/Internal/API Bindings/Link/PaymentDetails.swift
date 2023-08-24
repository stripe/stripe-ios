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
        case isDefault
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
    }
}

// MARK: - Details.Card
extension ConsumerPaymentDetails.Details {
    final class Card: Codable {
        let expiryYear: Int
        let expiryMonth: Int
        let brand: String
        let last4: String
        let checks: CardChecks?

        private enum CodingKeys: String, CodingKey {
            case expiryYear = "expYear"
            case expiryMonth = "expMonth"
            case brand
            case last4
            case checks
        }

        /// A frontend convenience property, i.e. not part of the API Object
        /// As such this is deliberately omitted from CodingKeys
        var cvc: String?
    }
}

// MARK: - Details.Card - Helpers
extension ConsumerPaymentDetails.Details.Card {

    var shouldRecollectCardCVC: Bool {
        switch checks?.cvcCheck {
        case .fail, .unavailable, .unchecked:
            return true
        default:
            return false
        }
    }

    var expiryDate: CardExpiryDate {
        return CardExpiryDate(month: expiryMonth, year: expiryYear)
    }

    var hasExpired: Bool {
        return expiryDate.expired()
    }

    var stpBrand: STPCardBrand {
        return STPPaymentMethodCard.brand(from: brand)
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
    }
}

extension ConsumerPaymentDetails {
    var cvc: String? {
        switch details {
        case .card(let card):
            return card.cvc
        case .bankAccount:
            return nil
        case .unparsable:
            return nil
        }
    }

}
