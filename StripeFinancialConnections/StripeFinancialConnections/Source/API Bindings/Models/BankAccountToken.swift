//
//  BankAccountToken.swift
//  StripeFinancialConnections
//
//  Created by Vardges Avetisyan on 4/8/22.
//

import Foundation
@_spi(STP) import StripeCore

public extension StripeAPI {

    struct BankAccountToken {

        // MARK: - Types

        public struct BankAccount {
            public let id: String
            public let accountHolderName: String?
            public let bankName: String?
            public let country: String
            public let currency: String
            public let fingerprint: String?
            public let last4: String
            public let routingNumber: String?
            public let status: String
        }

        public let id: String
        public let bankAccount: BankAccountToken.BankAccount?
        public let clientIp: String?
        public let livemode: Bool
        public let used: Bool
    }
}

// MARK: - Decodable

@_spi(STP) extension StripeAPI.BankAccountToken: Decodable {}
@_spi(STP) extension StripeAPI.BankAccountToken.BankAccount: Decodable {}
