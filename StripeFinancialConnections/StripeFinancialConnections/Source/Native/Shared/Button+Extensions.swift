//
//  Button+Extensions.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 9/30/22.
//

import Foundation
@_spi(STP) import StripeUICore

// Fixes a SwiftUI preview bug where previews will crash
// if `.financialConnectionsPrimary` is directly referenced
func FinancialConnectionsPrimaryButtonConfiguration() -> Button.Configuration {
    return .financialConnectionsPrimary
}

// Fixes a SwiftUI preview bug where previews will crash
// if `.financialConnectionsPrimary` is directly referenced
func FinancialConnectionsSecondaryButtonConfiguration() -> Button.Configuration {
    return .financialConnectionsSecondary
}

extension Button.Configuration {
    static var financialConnectionsPrimary: Button.Configuration {
        var primaryButtonConfiguration = Button.Configuration.primary()
        primaryButtonConfiguration.font = FinancialConnectionsFont.label(.largeEmphasized).uiFont
        primaryButtonConfiguration.cornerRadius = 12.0
        // default
        primaryButtonConfiguration.backgroundColor = .brand500
        primaryButtonConfiguration.foregroundColor = .white
        // disabled
        primaryButtonConfiguration.disabledBackgroundColor = .brand500
        primaryButtonConfiguration.disabledForegroundColor = .neutral0.withAlphaComponent(0.4)
        // pressed
        primaryButtonConfiguration.colorTransforms.highlightedBackground = .darken(amount: 0.23)  // this tries to simulate `brand600`
        primaryButtonConfiguration.colorTransforms.highlightedForeground = nil
        return primaryButtonConfiguration
    }

    static var financialConnectionsSecondary: Button.Configuration {
        var secondaryButtonConfiguration = Button.Configuration.secondary()
        secondaryButtonConfiguration.font = FinancialConnectionsFont.label(.largeEmphasized).uiFont
        secondaryButtonConfiguration.cornerRadius = 12.0
        // default
        secondaryButtonConfiguration.foregroundColor = .textDefault
        secondaryButtonConfiguration.backgroundColor = .neutral25
        // disabled
        secondaryButtonConfiguration.disabledForegroundColor = .textDefault.withAlphaComponent(0.4)
        secondaryButtonConfiguration.disabledBackgroundColor = .neutral25
        // pressed
        secondaryButtonConfiguration.colorTransforms.highlightedBackground = .darken(amount: 0.04)  // this tries to simulate `neutral100`
        secondaryButtonConfiguration.colorTransforms.highlightedForeground = nil
        return secondaryButtonConfiguration
    }
}
