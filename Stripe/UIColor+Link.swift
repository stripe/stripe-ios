//
//  UIColor+Link.swift
//  StripeiOS
//
//  Created by Ramon Torres on 11/1/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import UIKit

@_spi(STP) import StripeUICore

// MARK: - Custom colors

extension UIColor {

    /// Brand color for Link.
    ///
    /// Use it as accent color for controls and activity indicators.
    static let linkBrand: UIColor = UIColor(red: 0.2, green: 0.867, blue: 0.702, alpha: 1.0)

    /// Main background color.
    static let linkBackground: UIColor = .dynamic(
        light: .white,
        dark: UIColor(red: 0.11, green: 0.11, blue: 0.118, alpha: 1)
    )

    /// Background color for content layered on top of the main background.
    static let linkSecondaryBackground: UIColor = .dynamic(
        light: UIColor(red: 0.96, green: 0.97, blue: 0.98, alpha: 1.0),
        dark: UIColor(red: 0.17, green: 0.17, blue: 0.19, alpha: 1.0)
    )

    /// Color of the Link logo in the navigation bar.
    static let linkNavLogo: UIColor = .dynamic(
        light: UIColor(red: 0.639, green: 0.675, blue: 0.729, alpha: 1.0),
        dark: UIColor(red: 0.922, green: 0.922, blue: 0.961, alpha: 0.6)
    )

    /// Tint color of the nav. Affects the color of nav buttons.
    static let linkNavTint: UIColor = .dynamic(
        light: UIColor(red: 0.188, green: 0.192, blue: 0.239, alpha: 1.0),
        dark: UIColor(red: 0.922, green: 0.922, blue: 0.961, alpha: 0.6)
    )

    /// Color for borders and dividers.
    static let linkSeparator: UIColor = .dynamic(
        light: UIColor(red: 0.878, green: 0.902, blue: 0.922, alpha: 1),
        dark: UIColor(red: 0.471, green: 0.471, blue: 0.502, alpha: 0.36)
    )

    /// Border color for custom controls. Currently an alias of `linkSeparator`.
    static let linkControlBorder: UIColor = .linkSeparator

    /// Background color for custom controls.
    static let linkControlBackground: UIColor = .dynamic(
        light: .white,
        dark: UIColor(red: 0.17, green: 0.17, blue: 0.19, alpha: 1)
    )

    /// Background color to be used when a custom control is highlighted.
    static let linkControlHighlight: UIColor = .dynamic(
        light: UIColor(red: 0.95, green: 0.95, blue: 0.96, alpha: 1),
        dark: UIColor(white: 1, alpha: 0.07)
    )

    /// A very subtle color to be used on placeholder content of a control.
    ///
    /// - Note: Only recommended for shapes/non-text content due to very low contrast ratio with `linkControlBackground`.
    static let linkControlLightPlaceholder: UIColor = .dynamic(
        light: UIColor(red: 0.965, green: 0.973, blue: 0.98, alpha: 1),
        dark: UIColor(red: 0.471, green: 0.471, blue: 0.502, alpha: 0.36)
    )

    /// Background color of a badge.
    static let linkBadgeBackground: UIColor = .dynamic(
        light: UIColor(red: 0.96, green: 0.97, blue: 0.98, alpha: 1.0),
        dark: UIColor(white: 1, alpha: 0.1)
    )

    /// Foreground color of a badge.
    static let linkBadgeForeground: UIColor = .dynamic(
        light: UIColor(red: 0.416, green: 0.451, blue: 0.514, alpha: 1),
        dark: UIColor(red: 0.922, green: 0.922, blue: 0.961, alpha: 0.6)
    )

    /// Background color of the toast component.
    static let linkToastBackground: UIColor = UIColor(red: 0.19, green: 0.19, blue: 0.24, alpha: 1.0)

    /// Foreground color of the toast component.
    static let linkToastForeground: UIColor = .white

    /// Foreground color of the primary button.
    static let linkPrimaryButtonForeground: UIColor = UIColor(red: 0.012, green: 0.141, blue: 0.149, alpha: 1.0)

    /// Foreground color of the secondary button.
    static let linkSecondaryButtonForeground: UIColor = .dynamic(
        light: UIColor(red: 0.416, green: 0.451, blue: 0.514, alpha: 1.0),
        dark: .white
    )

    // TODO(ramont): Add color for dark mode
    static let linkDangerBackground: UIColor = .dynamic(
        light: UIColor(red: 1.0, green: 0.906, blue: 0.949, alpha: 1.0),
        dark: UIColor(red: 1.0, green: 0.906, blue: 0.949, alpha: 1.0)
    )

    // TODO(ramont): Add color for dark mode
    static let linkDangerForeground: UIColor = .dynamic(
        light: UIColor(red: 1.0, green: 0.184, blue: 0.298, alpha: 1.0),
        dark: UIColor(red: 1.0, green: 0.184, blue: 0.298, alpha: 1.0)
    )
}
