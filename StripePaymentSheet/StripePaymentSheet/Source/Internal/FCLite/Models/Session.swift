//
//  Session.swift
//  StripePaymentSheet
//
//  Created by Mat Schmid on 2025-03-12.
//

import Foundation

/// https://docs.stripe.com/api/financial_connections/sessions/object
struct FinancialConnectionsSession: Decodable {
    /// A unique ID for this session.
    let id: String
    /// Details on the account used for payment.
    let paymentAccount: PaymentAccount?

    enum CodingKeys: String, CodingKey {
        case id
        case paymentAccount = "payment_account"
    }
}

enum PaymentAccount: Decodable {
    case linkedAccount(LinkedAccount)
    case bankAccount(BankAccount)
    case unparsable

    /// Per API specs, `paymentAccount` is a polymorphic field. We are translating it to an enum with associated types.
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let value = try? container.decode(LinkedAccount.self) {
            self = .linkedAccount(value)
        } else if let value = try? container.decode(BankAccount.self) {
            self = .bankAccount(value)
        } else {
            self = .unparsable
        }
    }

    struct LinkedAccount: Decodable {
        let id: String
        let displayName: String?
        let institutionName: String
        let last4: String?

        enum CodingKeys: String, CodingKey {
            case id
            case displayName = "display_name"
            case institutionName = "institution_name"
            case last4
        }
    }

    struct BankAccount: Decodable {
        let id: String
        let bankName: String?
        let last4: String
        let routingNumber: String?

        enum CodingKeys: String, CodingKey {
            case id
            case bankName = "bank_name"
            case last4
            case routingNumber = "routing_number"
        }
    }
}
