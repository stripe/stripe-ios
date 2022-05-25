//
//  FinancialConnectionsSession.swift
//  StripeFinancialConnections
//
//  Created by Vardges Avetisyan on 1/19/22.
//

import Foundation
@_spi(STP) import StripeCore

public extension StripeAPI {

    /**
     Financial Connections Session is the programatic representation of the session for connecting financial accounts.
     - seealso: https://stripe.com/docs/api/financial_connections/session
     */
    struct FinancialConnectionsSession {

        // MARK: - Types

        /// An object representing a list of FinancialConnectionsAccounts.
        public struct AccountList {
            public let data: [StripeAPI.FinancialConnectionsAccount]
            /** True if this list has another page of items after this one that can be fetched. */
            public let hasMore: Bool

            // MARK: - Internal Init

            internal init(data: [StripeAPI.FinancialConnectionsAccount],
                          hasMore: Bool) {
                self.data = data
                self.hasMore = hasMore
            }
        }

        @_spi(STP) public enum PaymentAccount: Decodable {

            // MARK: - Types

            @_spi(STP) public struct BankAccount: Decodable {
                public let bankName: String?
                public let id: String
                public let last4: String
                public let routingNumber: String?
            }

            case linkedAccount(StripeAPI.FinancialConnectionsAccount)
            case bankAccount(StripeAPI.FinancialConnectionsSession.PaymentAccount.BankAccount)
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
                } else if let value = try? container.decode(FinancialConnectionsSession.PaymentAccount.BankAccount.self) {
                    self = .bankAccount(value)
                } else {
                    self = .unparsable
                }
            }
        }

        // MARK: - Properties

        public let clientSecret: String
        public let id: String
        public let accounts: FinancialConnectionsSession.AccountList
        public let livemode: Bool
        @_spi(STP) public let paymentAccount: PaymentAccount?
        @_spi(STP) public let bankAccountToken: BankAccountToken?

        // MARK: - Internal Init

        internal init(clientSecret: String,
                      id: String,
                      accounts: FinancialConnectionsSession.AccountList,
                      livemode: Bool,
                      paymentAccount: PaymentAccount?,
                      bankAccountToken: BankAccountToken?) {
            self.clientSecret = clientSecret
            self.id = id
            self.accounts = accounts
            self.livemode = livemode
            self.paymentAccount = paymentAccount
            self.bankAccountToken = bankAccountToken
        }

        // MARK: - Decodable

        enum CodingKeys: String, CodingKey {
            case clientSecret = "client_secret"
            case id = "id"
            case accounts = "accounts"
            case linkedAccounts = "linked_accounts"
            case livemode = "livemode"
            case paymentAccount = "payment_account"
            case bankAccountToken = "bank_account_token"
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let accounts: FinancialConnectionsSession.AccountList
            do {
                accounts = try container.decode(FinancialConnectionsSession.AccountList.self, forKey: .accounts)
            } catch {
                accounts = try container.decode(FinancialConnectionsSession.AccountList.self, forKey: .linkedAccounts)
            }
            self.init(clientSecret: try container.decode(String.self, forKey: .clientSecret),
                      id: try container.decode(String.self, forKey: .id),
                      accounts: accounts,
                      livemode: try container.decode(Bool.self, forKey: .livemode),
                      paymentAccount: try? container.decode(PaymentAccount.self, forKey: .paymentAccount),
                      bankAccountToken: try? container.decode(BankAccountToken.self, forKey: .bankAccountToken))
        }
    }
}


// MARK: - Decodable

@_spi(STP) extension StripeAPI.FinancialConnectionsSession: Decodable {}
@_spi(STP) extension StripeAPI.FinancialConnectionsSession.AccountList: Decodable {}
