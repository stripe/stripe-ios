//
//  LinkAccountSession.swift
//  StripeConnections
//
//  Created by Vardges Avetisyan on 1/19/22.
//

import Foundation
@_spi(STP) import StripeCore


public extension StripeAPI {

    struct LinkAccountSession: StripeDecodable {
        public let clientSecret: String
        public let id: String
        public let linkedAccounts: LinkedAccountList
        public let livemode: Bool
        public var _allResponseFieldsStorage: NonEncodableParameters?
    }
}
