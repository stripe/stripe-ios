//
//  FinancialConnectionsAccount.swift
//  StripeFinancialConnections
//
//  Created by Vardges Avetisyan on 11/17/21.
//

import Foundation
@_spi(STP) import StripeCore

public extension StripeAPI {

    /// A Financial Connections Account represents an account that exists outside of Stripe, to which you have been granted some degree of access.
    /// - seealso: https://stripe.com/docs/api/financial_connections/accounts/object
    struct FinancialConnectionsAccount {

        // MARK: - Types

        public struct BalanceRefresh {
            @frozen public enum Status: String, SafeEnumCodable, Equatable {
                case failed = "failed"
                case pending = "pending"
                case succeeded = "succeeded"
                case unparsable
            }
            /** The time at which the last refresh attempt was initiated. Measured in seconds since the Unix epoch. */
            public let lastAttemptedAt: Int
            public let status: Status
        }

        public struct CashBalance {
            /** The funds available to the account holder. Typically this is the current balance less any holds.  Each key is a three-letter [ISO currency code](https://www.iso.org/iso-4217-currency-codes.html), in lowercase.  Each value is an integer amount. A positive amount indicates money owed to the account holder. A negative amount indicates money owed by the account holder. */
            public let available: [String: Int]?
        }

        public struct CreditBalance {
            /** The credit that has been used by the account holder.  Each key is a three-letter [ISO currency code](https://www.iso.org/iso-4217-currency-codes.html), in lowercase.  Each value is a integer amount. A positive amount indicates money owed to the account holder. A negative amount indicates money owed by the account holder. */
            public let used: [String: Int]?
        }

        public struct Balance {
            @frozen public enum ModelType: String, SafeEnumCodable, Equatable {
                case cash = "cash"
                case credit = "credit"
                case unparsable
            }
            /** The time that the external institution calculated this balance. Measured in seconds since the Unix epoch. */
            public let asOf: Int
            public let cash: CashBalance?
            public let credit: CreditBalance?
            /** The balances owed to (or by) the account holder.  Each key is a three-letter [ISO currency code](https://www.iso.org/iso-4217-currency-codes.html), in lowercase.  Each value is a integer amount. A positive amount indicates money owed to the account holder. A negative amount indicates money owed by the account holder. */
            public let current: [String: Int]
            public let type: ModelType
        }

        public struct OwnershipRefresh: Codable, Equatable {
            @frozen public enum Status: String, SafeEnumCodable, Equatable {
                case failed = "failed"
                case pending = "pending"
                case succeeded = "succeeded"
                case unparsable
            }
            /// The time at which the last refresh attempt was initiated. Measured in seconds since the Unix epoch.
            public let lastAttemptedAt: Int
            /// The status of the last refresh attempt.
            public let status: OwnershipRefresh.Status
        }

        @frozen public enum Category: String, SafeEnumCodable, Equatable {
            case cash = "cash"
            case credit = "credit"
            case investment = "investment"
            case other = "other"
            case unparsable
        }

        @frozen public enum Permissions: String, SafeEnumCodable, Equatable {
            case balances = "balances"
            case ownership = "ownership"
            case paymentMethod = "payment_method"
            case transactions = "transactions"
            case accountNumbers = "account_numbers"
            case unparsable
        }

        @frozen public enum Status: String, SafeEnumCodable, Equatable {
            case active = "active"
            case disconnected = "disconnected"
            case inactive = "inactive"
            case unparsable
        }

        @frozen public enum Subcategory: String, SafeEnumCodable, Equatable {
            case checking = "checking"
            case creditCard = "credit_card"
            case lineOfCredit = "line_of_credit"
            case mortgage = "mortgage"
            case other = "other"
            case savings = "savings"
            case unparsable
        }

        @frozen public enum SupportedPaymentMethodTypes: String, SafeEnumCodable, Equatable {
            case link = "link"
            case usBankAccount = "us_bank_account"
            case unparsable
        }

        // MARK: - Public Fields

        public let balance: Balance?
        public let balanceRefresh: BalanceRefresh?
        public let ownership: String?
        /// The state of the most recent attempt to refresh the account owners.
        public let ownershipRefresh: OwnershipRefresh?
        public let displayName: String?
        public let institutionName: String
        public let last4: String?
        public let category: Category
        public let created: Int
        public let id: String
        public let livemode: Bool
        public let permissions: [Permissions]?
        public let status: Status
        public let subcategory: Subcategory
        /** The [PaymentMethod type](https://stripe.com/docs/api/payment_methods/object#payment_method_object-type)(s) that can be created from this FinancialConnectionsAccount. */
        public let supportedPaymentMethodTypes: [SupportedPaymentMethodTypes]

        // MARK: Internal

        // StripeConnect needs to retain these API properties so they
        // can be re-encoded and forwarded to Javascript

        let object: String
    }

}

// MARK: - Codable & Equatable

@_spi(STP) extension StripeAPI.FinancialConnectionsAccount: Codable, Equatable {}
@_spi(STP) extension StripeAPI.FinancialConnectionsAccount.BalanceRefresh: Codable, Equatable {}
@_spi(STP) extension StripeAPI.FinancialConnectionsAccount.CashBalance: Codable, Equatable {}
@_spi(STP) extension StripeAPI.FinancialConnectionsAccount.CreditBalance: Codable, Equatable {}
@_spi(STP) extension StripeAPI.FinancialConnectionsAccount.Balance: Codable, Equatable {}
