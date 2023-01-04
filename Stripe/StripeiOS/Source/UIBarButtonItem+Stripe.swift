//
//  UIBarButtonItem+Stripe.swift
//  StripeiOS
//
//  Created by Jack Flintermann on 5/18/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

@_spi(STP) import StripeUICore
import UIKit

extension UIBarButtonItem {
    @objc(stp_setTheme:) func stp_setTheme(_ theme: STPTheme) {
        let image = backgroundImage(for: .normal, barMetrics: .default)
        if let image = image {
            let enabledImage: UIImage = STPLegacyImageLibrary.image(
                withTintColor: theme.accentColor,
                for: image
            )
            let disabledImage: UIImage = STPLegacyImageLibrary.image(
                withTintColor: theme.secondaryForegroundColor,
                for: image
            )
            setBackgroundImage(enabledImage, for: .normal, barMetrics: .default)
            setBackgroundImage(disabledImage, for: .disabled, barMetrics: .default)
        }

        tintColor = isEnabled ? theme.accentColor : theme.secondaryForegroundColor

        setTitleTextAttributes(
            [
                NSAttributedString.Key.font: style == .plain ? theme.font : theme.emphasisFont,
                NSAttributedString.Key.foregroundColor: theme.accentColor,
            ],
            for: .normal
        )

        setTitleTextAttributes(
            [
                NSAttributedString.Key.font: style == .plain ? theme.font : theme.emphasisFont,
                NSAttributedString.Key.foregroundColor: theme.secondaryForegroundColor,
            ],
            for: .disabled
        )

        setTitleTextAttributes(
            [
                NSAttributedString.Key.font: style == .plain ? theme.font : theme.emphasisFont,
                NSAttributedString.Key.foregroundColor: theme.accentColor,
            ],
            for: .highlighted
        )
    }
}
