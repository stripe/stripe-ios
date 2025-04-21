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

            internal init(
                data: [StripeAPI.FinancialConnectionsAccount],
                hasMore: Bool
            ) {
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
                
                /// Whether the account should be considered instantly verified. This field isn't part of the API response 
                /// and is being set later on.
                public var instantlyVerified: Bool = false
                
                private enum CodingKeys: String, CodingKey {
                    case bankName, id, last4, routingNumber
                }
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

        enum Status: String, SafeEnumCodable, Equatable {
            case pending
            case succeeded
            case failed
            case cancelled
            case unparsable
        }

        struct StatusDetails: Decodable {
            struct CancelledStatusDetails: Decodable {
                enum TerminalStateReason: String, SafeEnumCodable, Equatable {
                    case other
                    case customManualEntry = "custom_manual_entry"
                    case unparsable
                }

                let reason: TerminalStateReason
            }

            let cancelled: CancelledStatusDetails?
        }

        // MARK: - Properties

        public let clientSecret: String
        public let id: String
        public let accounts: FinancialConnectionsSession.AccountList
        public let livemode: Bool
        @_spi(STP) public let paymentAccount: PaymentAccount?
        @_spi(STP) public let bankAccountToken: BankAccountToken?
        let status: Status?
        let statusDetails: StatusDetails?

        // MARK: - Internal Init

        internal init(
            clientSecret: String,
            id: String,
            accounts: FinancialConnectionsSession.AccountList,
            livemode: Bool,
            paymentAccount: PaymentAccount?,
            bankAccountToken: BankAccountToken?,
            status: Status?,
            statusDetails: StatusDetails?
        ) {
            self.clientSecret = clientSecret
            self.id = id
            self.accounts = accounts
            self.livemode = livemode
            self.paymentAccount = paymentAccount
            self.bankAccountToken = bankAccountToken
            self.status = status
            self.statusDetails = statusDetails
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
            case status = "status"
            case statusDetails = "status_details"
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let accounts: FinancialConnectionsSession.AccountList
            do {
                accounts = try container.decode(FinancialConnectionsSession.AccountList.self, forKey: .accounts)
            } catch {
                accounts = try container.decode(FinancialConnectionsSession.AccountList.self, forKey: .linkedAccounts)
            }
            self.init(
                clientSecret: try container.decode(String.self, forKey: .clientSecret),
                id: try container.decode(String.self, forKey: .id),
                accounts: accounts,
                livemode: try container.decode(Bool.self, forKey: .livemode),
                paymentAccount: try? container.decode(PaymentAccount.self, forKey: .paymentAccount),
                bankAccountToken: try? container.decode(BankAccountToken.self, forKey: .bankAccountToken),
                status: try? container.decode(Status.self, forKey: .status),
                statusDetails: try? container.decode(StatusDetails.self, forKey: .statusDetails)
            )
        }
    }
}

// MARK: - Decodable

@_spi(STP) extension StripeAPI.FinancialConnectionsSession: Decodable {}
@_spi(STP) extension StripeAPI.FinancialConnectionsSession.AccountList: Decodable {}
