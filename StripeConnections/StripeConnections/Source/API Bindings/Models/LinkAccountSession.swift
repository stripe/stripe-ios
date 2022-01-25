//
//  LinkAccountSession.swift
//  StripeConnections
//
//  Created by Vardges Avetisyan on 1/19/22.
//

import Foundation
@_spi(STP) import StripeCore

public extension StripeAPI {

    struct LinkAccountSession {

        // MARK: - Types

        @_spi(STP) public struct BankAccount: StripeDecodable {
            public let bankName: String?
            public let id: String
            public let last4: String
            public let routingNumber: String?
            public var _allResponseFieldsStorage: NonEncodableParameters?
        }

        @_spi(STP) public enum PaymentAccount: Decodable {

            case linkedAccount(StripeAPI.LinkedAccount)
            case bankAccount(StripeAPI.LinkAccountSession.BankAccount)
            case unparsable

            // MARK: - Decodable

            /**
             Per API specification paymentAccount is a polymorphic field denoted by openAPI anyOf modifier.
             We are translating it to an enum with associated types.
             */
            public init(from decoder: Decoder) throws {
                let container = try decoder.singleValueContainer()
                if let value = try? container.decode(LinkedAccount.self) {
                    self = .linkedAccount(value)
                } else if let value = try? container.decode(LinkAccountSession.BankAccount.self) {
                    self = .bankAccount(value)
                } else {
                    self = .unparsable
                }
            }
        }

        // MARK: - Properties

        public let clientSecret: String
        public let id: String
        public let linkedAccounts: LinkedAccountList
        public let livemode: Bool
        @_spi(STP) public let paymentAccount: PaymentAccount?
        @_spi(STP) public var _allResponseFieldsStorage: NonEncodableParameters?

        // MARK: - Internal Init

        internal init(clientSecret: String,
                      id: String,
                      linkedAccounts: LinkedAccountList,
                      livemode: Bool,
                      paymentAccount: PaymentAccount?) {
            self.clientSecret = clientSecret
            self.id = id
            self.linkedAccounts = linkedAccounts
            self.livemode = livemode
            self.paymentAccount = paymentAccount
        }
    }
}


// MARK: - StripeDecodable

@_spi(STP) extension StripeAPI.LinkAccountSession: StripeDecodable {}
