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
    let billingAddress: BillingAddress?
    let billingEmailAddress: String?
    let nickname: String?
    var isDefault: Bool

    init(stripeID: String,
         details: Details,
         billingAddress: BillingAddress?,
         billingEmailAddress: String?,
         nickname: String?,
         isDefault: Bool
    ) {
        self.stripeID = stripeID
        self.details = details
        self.billingAddress = billingAddress
        self.billingEmailAddress = billingEmailAddress
        self.nickname = nickname
        self.isDefault = isDefault
    }

    private enum CodingKeys: String, CodingKey {
        case stripeID = "id"
        case billingAddress = "billing_address"
        case billingEmailAddress = "billing_email_address"
        case nickname
        case isDefault
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.stripeID = try container.decode(String.self, forKey: .stripeID)
        self.billingAddress = try? container.decode(BillingAddress.self, forKey: .billingAddress)
        self.billingEmailAddress = try? container.decode(String.self, forKey: .billingEmailAddress)
        let decodedNickname = try? container.decode(String.self, forKey: .nickname)
        if let decodedNickname, !decodedNickname.isEmpty {
            self.nickname = decodedNickname
        } else {
            self.nickname = nil
        }
        // The payment details are included in the dictionary, so we pass the whole dict to Details
        self.details = try decoder.singleValueContainer().decode(Details.self)
        self.isDefault = try container.decode(Bool.self, forKey: .isDefault)
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
        let expiryYear: Int
        let expiryMonth: Int
        let brand: String
        let networks: [String]
        let last4: String
        let funding: Funding
        let checks: CardChecks?

        private enum CodingKeys: String, CodingKey {
            case expiryYear = "expYear"
            case expiryMonth = "expMonth"
            case brand
            case networks
            case last4
            case funding
            case checks
        }

        /// A frontend convenience property, i.e. not part of the API Object
        /// As such this is deliberately omitted from CodingKeys
        var cvc: String?

        init(expiryYear: Int,
             expiryMonth: Int,
             brand: String,
             networks: [String],
             last4: String,
             funding: Funding,
             checks: CardChecks?
        ) {
            self.expiryYear = expiryYear
            self.expiryMonth = expiryMonth
            self.brand = brand
            self.networks = networks
            self.last4 = last4
            self.funding = funding
            self.checks = checks
        }
    }
}

// MARK: - Details.Card - Helpers
extension ConsumerPaymentDetails.Details.Card {
    enum Funding: String, SafeEnumCodable {
        case credit = "CREDIT"
        case debit = "DEBIT"
        case prepaid = "PREPAID"
        // Catch all
        case unparsable = ""

        var displayNameWithBrand: String {
            switch self {
            case .credit: String.Localized.Funding.credit
            case .debit: String.Localized.Funding.debit
            case .prepaid: String.Localized.Funding.prepaid
            case .unparsable: String.Localized.Funding.default
            }
        }
    }

    var shouldRecollectCardCVC: Bool {
        switch checks?.cvcCheck {
        case .fail, .unavailable, .unchecked, .stateInvalid:
            return true
        case .pass, .unparsable, nil:
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
        return STPCard.brand(from: brand)
    }

    var secondaryName: String {
        "•••• \(last4)"
    }

    func displayName(with nickname: String?) -> String? {
        if let nickname {
            return nickname
        }

        guard let formattedBrandName = STPCardBrandUtilities.stringFrom(stpBrand) else {
            return nil
        }

        return String(
            format: funding.displayNameWithBrand,
            formattedBrandName
        )
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
            return card.displayName(with: nickname) ?? card.secondaryName
        case .bankAccount(let bank):
            return "•••• \(bank.last4)"
        case .unparsable:
            return ""
        }
    }

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
