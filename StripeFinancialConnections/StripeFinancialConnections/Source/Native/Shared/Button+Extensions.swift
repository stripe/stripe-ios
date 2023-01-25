//
//  Button+Extensions.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 9/30/22.
//

import Foundation
@_spi(STP) import StripeUICore

extension Button.Configuration {
    static var financialConnectionsPrimary: Button.Configuration {
        var primaryButtonConfiguration = Button.Configuration.primary()
        primaryButtonConfiguration.font = .stripeFont(forTextStyle: .bodyEmphasized)
        // default
        primaryButtonConfiguration.backgroundColor = .textBrand
        primaryButtonConfiguration.foregroundColor = .white
        // disabled
        primaryButtonConfiguration.disabledBackgroundColor = .textBrand
        primaryButtonConfiguration.disabledForegroundColor = .white.withAlphaComponent(0.3)
        // pressed
        primaryButtonConfiguration.colorTransforms.highlightedBackground = .darken(amount: 0.23)  // this tries to simulate `brand600`
        primaryButtonConfiguration.colorTransforms.highlightedForeground = nil
        return primaryButtonConfiguration
    }

    static var financialConnectionsSecondary: Button.Configuration {
        var secondaryButtonConfiguration = Button.Configuration.secondary()
        secondaryButtonConfiguration.font = .stripeFont(forTextStyle: .bodyEmphasized)
        // default
        secondaryButtonConfiguration.foregroundColor = .textPrimary
        secondaryButtonConfiguration.backgroundColor = .backgroundContainer
        // disabled
        secondaryButtonConfiguration.disabledForegroundColor = .textPrimary.withAlphaComponent(0.3)
        secondaryButtonConfiguration.disabledBackgroundColor = .backgroundContainer
        // pressed
        secondaryButtonConfiguration.colorTransforms.highlightedBackground = .darken(amount: 0.04)  // this tries to simulate `neutral100`
        secondaryButtonConfiguration.colorTransforms.highlightedForeground = nil
        return secondaryButtonConfiguration
    }
}
