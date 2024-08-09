//
//  FinancialConnectionsSDKResult.swift
//  StripeCore
//
//  Created by Krisjanis Gaidis on 4/16/24.
//

import Foundation

@_spi(STP) @frozen public enum FinancialConnectionsSDKResult: Sendable {
    case completed(Completed)
    case cancelled
    case failed(error: Error)

    @_spi(STP) public enum Completed: Sendable {
        case financialConnections(FinancialConnectionsLinkedBank)
        case instantDebits(InstantDebitsLinkedBank)
    }
}
