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
        configuration.font = LinkUI.font(forTextStyle: .bodyEmphasized)
        configuration.insets = LinkUI.buttonMargins
        configuration.cornerRadius = LinkUI.cornerRadius

        // Colors
        configuration.backgroundColor = .linkBrand
        configuration.disabledBackgroundColor = .linkBrand
        configuration.foregroundColor = .white

        configuration.colorTransforms.disabledForeground = .setAlpha(amount: 0.5)
        configuration.colorTransforms.highlightedForeground = .darken(amount: 0.2)

        return configuration
    }

    static func linkSecondary() -> Self {
        var configuration: Button.Configuration = .linkPrimary()

        // Colors
        configuration.backgroundColor = .linkSecondaryBackground
        configuration.disabledBackgroundColor = .linkSecondaryBackground
        configuration.foregroundColor = .linkBrand

        return configuration
    }

    static func linkTertiary() -> Self {
        var configuration: Button.Configuration = .linkSecondary()
        configuration.foregroundColor = .darkGray
        return configuration
    }

    static func linkPlain() -> Self {
        var configuration: Button.Configuration = .plain()
        configuration.font = LinkUI.font(forTextStyle: .bodyEmphasized)
        configuration.foregroundColor = .linkBrand
        return configuration
    }

    static func linkBordered() -> Self {
        var configuration: Button.Configuration = .plain()
        configuration.font = LinkUI.font(forTextStyle: .detailEmphasized)
        configuration.insets = .insets(top: 4, leading: 12, bottom: 4, trailing: 12)
        configuration.borderWidth = 1
        configuration.cornerRadius = LinkUI.mediumCornerRadius

        // Colors
        configuration.foregroundColor = CompatibleColor.label
        configuration.backgroundColor = .clear
        configuration.borderColor = .linkControlBorder

        configuration.colorTransforms.highlightedForeground = .setAlpha(amount: 0.5)
        configuration.colorTransforms.highlightedBorder = .setAlpha(amount: 0.5)

        return configuration
    }

}
