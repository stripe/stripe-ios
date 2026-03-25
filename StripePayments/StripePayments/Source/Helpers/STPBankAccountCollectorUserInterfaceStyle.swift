//
//  STPBankAccountCollectorUserInterfaceStyle.swift
//  StripePayments
//
//  Created by Mat Schmid on 2025-02-12.
//

import Foundation
@_spi(STP) import StripeCore

/// Style options for colors in the bank account collector.
@objc @frozen public enum STPBankAccountCollectorUserInterfaceStyle: Int {
    /// (default) The bank account collector will automatically switch between light and dark mode compatible colors based on device settings.
    case automatic = 0

    /// The bank account collector will always use colors appropriate for light mode UI.
    case alwaysLight

    /// The bank account collector will always use colors appropriate for dark mode UI.
    case alwaysDark
}

extension STPBankAccountCollectorUserInterfaceStyle {
    var asFinancialConnectionsConfigurationStyle: FinancialConnectionsStyle {
        switch self {
        case .automatic: return .automatic
        case .alwaysLight: return .alwaysLight
        case .alwaysDark: return .alwaysDark
        }
    }
}
