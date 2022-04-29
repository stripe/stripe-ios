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
        public let linkedAccounts: FinancialConnectionsSession.AccountList
        public let livemode: Bool
        @_spi(STP) public let paymentAccount: PaymentAccount?
        @_spi(STP) public let bankAccountToken: BankAccountToken?

        // MARK: - Internal Init

        internal init(clientSecret: String,
                      id: String,
                      linkedAccounts: FinancialConnectionsSession.AccountList,
                      livemode: Bool,
                      paymentAccount: PaymentAccount?,
                      bankAccountToken: BankAccountToken?) {
            self.clientSecret = clientSecret
            self.id = id
            self.linkedAccounts = linkedAccounts
            self.livemode = livemode
            self.paymentAccount = paymentAccount
            self.bankAccountToken = bankAccountToken
        }
    }
}


// MARK: - Decodable

@_spi(STP) extension StripeAPI.FinancialConnectionsSession: Decodable {}
@_spi(STP) extension StripeAPI.FinancialConnectionsSession.AccountList: Decodable {}
