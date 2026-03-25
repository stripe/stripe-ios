//
//  FinancialConnectionsStyle.swift
//  StripeCore
//
//  Created by Mat Schmid on 2025-02-12.
//

import Foundation

/// Intermediary object between `PaymentSheet.Configuration.UserInterfaceStyle` / `STPBankAccountCollectorStyle`
/// and `FinancialConnectionsSheet.Configuration.UserInterfaceStyle`.
@_spi(STP) @frozen public enum FinancialConnectionsStyle {
    case automatic
    case alwaysLight
    case alwaysDark
}
