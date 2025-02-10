//
//  FinancialConnectionsConfiguration.swift
//  StripeCore
//
//  Created by Mat Schmid on 2025-02-10.
//

import Foundation

/// Intermediary object between `PaymentSheet.Configuration` / `STPBankAccountCollectorConfiguration`
/// and `FinancialConnectionsSheet.Configuration`.
@_spi(STP) public struct FinancialConnectionsConfiguration {
    @_spi(STP) @frozen public enum StyleConfig {
        case automatic
        case alwaysLight
        case alwaysDark
    }

    @_spi(STP) public let styleConfig: StyleConfig

    @_spi(STP) public init(styleConfig: StyleConfig = .automatic) {
        self.styleConfig = styleConfig
    }
}
