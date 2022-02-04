//
//  Button+Link.swift
//  StripeiOS
//
//  Created by Ramon Torres on 12/1/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import UIKit
@_spi(STP) import StripeUICore

extension Button.Configuration {

    static func linkPrimary() -> Self {
        var configuration: Button.Configuration = .primary()
        configuration.cornerRadius = LinkUI.cornerRadius
        configuration.backgroundColor = .linkBrand
        configuration.disabledBackgroundColor = .linkBrand
        configuration.foregroundColor = UIColor.white
        configuration.disabledForegroundColor = UIColor.white.withAlphaComponent(0.5)
        configuration.insets = LinkUI.buttonMargins
        configuration.font = LinkUI.font(forTextStyle: .bodyEmphasized)
        return configuration
    }

    static func linkSecondary() -> Self {
        var configuration: Button.Configuration = .secondary()
        configuration.cornerRadius = LinkUI.cornerRadius
        configuration.backgroundColor = .linkSecondaryBackground
        configuration.insets = LinkUI.buttonMargins
        configuration.font = LinkUI.font(forTextStyle: .bodyEmphasized)
        return configuration
    }
    
    static func linkTertiary() -> Self {
        var configuration: Button.Configuration = .secondary()
        configuration.cornerRadius = LinkUI.cornerRadius
        configuration.backgroundColor = .linkSecondaryBackground
        configuration.insets = LinkUI.buttonMargins
        configuration.font = LinkUI.font(forTextStyle: .bodyEmphasized)
        configuration.foregroundColor = .darkGray
        return configuration
    }

}
