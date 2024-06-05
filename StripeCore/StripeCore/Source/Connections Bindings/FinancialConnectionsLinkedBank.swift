//
//  FinancialConnectionsLinkedBank.swift
//  StripeCore
//
//  Created by Krisjanis Gaidis on 4/16/24.
//

import Foundation

@_spi(STP) public protocol FinancialConnectionsLinkedBank {
    var sessionId: String { get }
    var accountId: String { get }
    var displayName: String? { get }
    var bankName: String? { get }
    var last4: String? { get }
    var instantlyVerified: Bool { get }
}
