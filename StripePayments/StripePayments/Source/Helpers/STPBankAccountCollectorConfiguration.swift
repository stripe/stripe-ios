//
//  STPBankAccountCollectorConfiguration.swift
//  StripePayments
//
//  Created by Mat Schmid on 2025-02-10.
//

import Foundation
@_spi(STP) import StripeCore

/// Configuration for the bank account collector.
public struct STPBankAccountCollectorConfiguration {
    /// Style options for colors in the bank account collector.
    @frozen public enum UserInterfaceStyle {
        /// (default) The bank account collector will automatically switch between light and dark mode compatible colors based on device settings.
        case automatic

        /// The bank account collector will always use colors appropriate for light mode UI.
        case alwaysLight

        /// The bank account collector will always use colors appropriate for dark mode UI.
        case alwaysDark
    }

    public var style: UserInterfaceStyle

    public init(style: UserInterfaceStyle = .automatic) {
        self.style = style
    }
}

// MARK: Tramsformation helpers
extension STPBankAccountCollectorConfiguration {
    var asFinancialConnectionsConfiguration: FinancialConnectionsConfiguration {
        let styleConfig: FinancialConnectionsConfiguration.StyleConfig = {
            switch style {
            case .automatic: return .automatic
            case .alwaysLight: return .alwaysLight
            case .alwaysDark: return .alwaysDark
            }
        }()
        return .init(styleConfig: styleConfig)
    }
}
