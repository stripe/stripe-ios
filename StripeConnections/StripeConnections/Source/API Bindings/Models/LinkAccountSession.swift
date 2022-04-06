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
