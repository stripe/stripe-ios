//
//  FinancialConnectionsLinkedBank.swift
//  StripeCore
//
//  Created by Krisjanis Gaidis on 4/16/24.
//

import Foundation

@_spi(STP) public struct FinancialConnectionsLinkedBank: Equatable {
    public let sessionId: String
    public let accountId: String
    public let displayName: String?
    public let bankName: String?
    public let last4: String?
    public let instantlyVerified: Bool

    public init(
        sessionId: String,
        accountId: String,
        displayName: String?,
        bankName: String?,
        last4: String?,
        instantlyVerified: Bool
    ) {
        self.sessionId = sessionId
        self.accountId = accountId
        self.displayName = displayName
        self.bankName = bankName
        self.last4 = last4
        self.instantlyVerified = instantlyVerified
    }
}
