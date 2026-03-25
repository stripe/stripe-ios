//
//  Button+Link.swift
//  StripePaymentSheet
//
//  Created by Ramon Torres on 12/1/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

@_spi(STP) import StripeUICore
import UIKit

extension Button.Configuration {

    static func linkPrimary() -> Self {
        var configuration: Button.Configuration = .primary()
        configuration.font = LinkUI.font(forTextStyle: .bodyEmphasized)
        configuration.insets = LinkUI.buttonMargins
        configuration.cornerRadius = LinkUI.cornerRadius

        // Colors
        configuration.foregroundColor = .linkContentOnPrimaryButton
        configuration.backgroundColor = .linkIconBrand
        configuration.disabledBackgroundColor = .linkIconBrand

        configuration.colorTransforms.disabledForeground = .setAlpha(amount: 0.5)
        configuration.colorTransforms.highlightedForeground = .darken(amount: 0.2)

        return configuration
    }

    static func linkPlain(foregroundColor: UIColor = .linkTextBrand) -> Self {
        var configuration: Button.Configuration = .plain()
        configuration.font = LinkUI.font(forTextStyle: .bodyEmphasized)
        configuration.foregroundColor = foregroundColor
        configuration.disabledForegroundColor = nil
        configuration.colorTransforms.highlightedForeground = .setAlpha(amount: 0.4)
        configuration.colorTransforms.disabledForeground = .setAlpha(amount: 0.3)
        return configuration
    }
}
