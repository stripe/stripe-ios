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
    /// The client secret for this session.
    let clientSecret: String
    /// Has the value true if the object exists in live mode or the value false if the object exists in test mode.
    let livemode: Bool
    /// The accounts that were collected as part of this Session.
    let accounts: AccountList?
    /// Details on the account used for payment.
    let paymentAccount: PaymentAccount?

    enum CodingKeys: String, CodingKey {
        case id
        case clientSecret = "client_secret"
        case livemode
        case accounts
        case paymentAccount = "payment_account"
    }
}

extension FinancialConnectionsSession {
    enum PaymentAccount: Decodable {

        // MARK: - Types

        struct BankAccount: Decodable {
            public let bankName: String?
            public let id: String
            public let last4: String
            public let routingNumber: String?

            private enum CodingKeys: String, CodingKey {
                case bankName, id, last4, routingNumber
            }
        }

        case linkedAccount(FinancialConnectionsAccount)
        case bankAccount(PaymentAccount.BankAccount)
        case unparsable

        // MARK: - Decodable

        /**
         Per API specification paymentAccount is a polymorphic field denoted by openAPI anyOf modifier.
         We are translating it to an enum with associated types.
         */
        public init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let value = try? container.decode(FinancialConnectionsAccount.self) {
                self = .linkedAccount(value)
            } else if let value = try? container.decode(PaymentAccount.BankAccount.self) {
                self = .bankAccount(value)
            } else {
                self = .unparsable
            }
        }
    }

    struct AccountList: Decodable {
        let data: [FinancialConnectionsAccount]
        /// True if this list has another page of items after this one that can be fetched.
        let hasMore: Bool

        enum CodingKeys: String, CodingKey {
            case data
            case hasMore = "has_more"
        }
    }

    struct FinancialConnectionsAccount: Decodable {
        /// A unique ID for this Financial Connections Account.
        let id: String
        /// Has the value true if the object exists in live mode or the value false if the object exists in test mode.
        let livemode: Bool
        let displayName: String?
        /// The current status of the account. Either active, inactive, or disconnected.
        let status: AccountStatus
        let institutionName: String
        let last4: String?
        /// The UNIX timestamp (in milliseconds) of the date this account was created.
        let created: Int
        /// The balance of this account.
        let balance: Balance?
        /// The last balance refresh. Includes the timestamp and the status.
        let balanceRefresh: BalanceRefresh?
        /// The category of this account, either cash, credit, investment, or other.
        let category: Category
        /// The subcategory of this account, either checking, credit_card, line_of_credit, mortgage, savings, or other.
        let subcategory: Subcategory
        /// Permissions requested for accounts collected during this session.
        let permissions: [Permission]?
        /// The supported payment method types for this account.
        let supportedPaymentMethodTypes: [PaymentMethodType]

        enum CodingKeys: String, CodingKey {
            case id
            case livemode
            case displayName = "display_name"
            case status
            case institutionName = "institution_name"
            case last4
            case created
            case balance
            case balanceRefresh = "balance_refresh"
            case category
            case subcategory
            case permissions
            case supportedPaymentMethodTypes = "supported_payment_method_types"
        }
    }

    struct Balance: Decodable {
        /// The UNIX timestamp (in milliseconds) of time that the external institution calculated this balance.
        let asOf: Int
        /// The type of this balance, either cash or credit.
        let type: BalanceType
        /// The funds available to the account holder. Typically this is the current balance less any holds.
        let cash: [String: Int]?
        /// The credit that has been used by the account holder.
        let credit: [String: Int]?
        /// The balances owed to (or by) the account holder.
        let current: [String: Int]

        enum CodingKeys: String, CodingKey {
            case asOf = "as_of"
            case type
            case cash
            case credit
            case current
        }
    }

    struct BalanceRefresh: Decodable {
        let status: BalanceRefreshStatus
        /// The UNIX timestamp (in milliseconds) of the time at which the last refresh attempt was initiated.
        let lastAttemptedAt: Int

        enum CodingKeys: String, CodingKey {
            case status
            case lastAttemptedAt = "last_attempted_at"
        }
    }

    enum AccountStatus: String, Decodable {
        case active
        case inactive
        case disconnected
    }

    enum Category: String, Decodable {
        case cash
        case credit
        case investment
        case other
    }

    enum PaymentMethodType: String, Decodable {
        case usBankAccount = "us_bank_account"
        case link
    }

    enum Permission: String, Decodable {
        case balances
        case ownership
        case paymentMethod = "payment_method"
        case transactions
        case accountNumbers = "account_numbers"
    }

    enum Subcategory: String, Decodable {
        case checking
        case creditCard = "credit_card"
        case lineOfCredit = "line_of_credit"
        case mortgage
        case savings
        case other
    }

    enum BalanceType: String, Codable {
        case cash
        case credit
    }

    enum BalanceRefreshStatus: String, Codable {
        case failed
        case pending
        case succeeded
    }
}
