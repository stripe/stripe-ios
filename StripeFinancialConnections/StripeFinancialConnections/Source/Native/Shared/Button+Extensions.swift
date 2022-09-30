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
        primaryButtonConfiguration.backgroundColor = .textBrand
        primaryButtonConfiguration.foregroundColor = .white
        // disabed state is shown by making the whole button 0.5 opacity
        // we can't make `backgroundColor` and foregroundColor` be 0.5 opacity
        // because it causes color blending issues
        primaryButtonConfiguration.disabledBackgroundColor = primaryButtonConfiguration.backgroundColor
        primaryButtonConfiguration.disabledForegroundColor = primaryButtonConfiguration.foregroundColor
        return primaryButtonConfiguration
    }
    
    static var financialConnectionsSecondary: Button.Configuration {
        var secondaryButtonConfiguration = Button.Configuration.secondary()
        secondaryButtonConfiguration.font = .stripeFont(forTextStyle: .bodyEmphasized)
        secondaryButtonConfiguration.foregroundColor = .textSecondary
        secondaryButtonConfiguration.backgroundColor = .borderNeutral
        return secondaryButtonConfiguration
    }
}
