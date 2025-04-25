//
//  UIColor+Link.swift
//  StripePaymentSheet
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
    static var linkBrand: UIColor {
        UIColor(red: 0, green: 0.84, blue: 0.44, alpha: 1.0)
    }

    /// Darker version of the brand color.
    ///
    /// Use it as accent color on small UI elements or text links.
    static let linkBrandDark: UIColor = UIColor(red: 0.020, green: 0.659, blue: 0.498, alpha: 1.0)

    /// Main background color.
    static let linkBackground: UIColor = .dynamic(
        light: .white,
        dark: UIColor(red: 0.11, green: 0.11, blue: 0.118, alpha: 1)
    )

    /// Level 400 variant of Link brand color.
    ///
    /// Use for separator bars over the Link brand color.
    static var linkBrand400: UIColor {
        UIColor(red: 0.0, green: 0.64, blue: 0.33, alpha: 1.0)
    }

    /// Level 500 variant of Link brand color
    ///
    /// Use for text buttons.
    static var linkBrand500: UIColor {
        UIColor(red: 0, green: 0.52, blue: 0.27, alpha: 1)
    }

    /// Color of the Link logo in the navigation bar.
    static let linkNavLogo: UIColor = .dynamic(
        light: UIColor(red: 0.114, green: 0.224, blue: 0.267, alpha: 1.0),
        dark: .white
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
        light: UIColor(red: 0.922, green: 0.933, blue: 0.945, alpha: 1.0),
        dark: UIColor(red: 0.471, green: 0.471, blue: 0.502, alpha: 0.36)
    )

    /// Background color of the toast component.
    static let linkToastBackground: UIColor = UIColor(red: 0.19, green: 0.19, blue: 0.24, alpha: 1.0)

    /// Foreground color of the toast component.
    static let linkToastForeground: UIColor = .white

    /// Foreground color of the primary button.
    static var linkPrimaryButtonForeground: UIColor {
        UIColor(red: 0, green: 0.12, blue: 0.06, alpha: 1.0)
    }

    /// Foreground color of the secondary button.
    static let linkSecondaryButtonForeground: UIColor = .dynamic(
        light: UIColor(red: 0.114, green: 0.224, blue: 0.267, alpha: 1.0),
        dark: UIColor(red: 0.020, green: 0.659, blue: 0.498, alpha: 1.0)
    )

    /// Background color of the secondary button/
    static let linkSecondaryButtonBackground: UIColor = .dynamic(
        light: UIColor(red: 0.965, green: 0.973, blue: 0.980, alpha: 1.0),
        dark: UIColor(red: 0.455, green: 0.455, blue: 0.502, alpha: 0.18)
    )

    /// Background color of a neutral badge or notice.
    static let linkNeutralBackground: UIColor = .dynamic(
        light: UIColor(red: 0.96, green: 0.97, blue: 0.98, alpha: 1.0),
        dark: UIColor(white: 1, alpha: 0.1)
    )

    /// Foreground color of a neutral badge or notice.
    static let linkNeutralForeground: UIColor = .dynamic(
        light: UIColor(red: 0.416, green: 0.451, blue: 0.514, alpha: 1),
        dark: UIColor(red: 0.922, green: 0.922, blue: 0.961, alpha: 0.6)
    )

    /// Background color of an error badge or notice.
    static let linkDangerBackground: UIColor = .dynamic(
        light: UIColor(red: 1.0, green: 0.906, blue: 0.949, alpha: 1.0),
        dark: UIColor(red: 0.996, green: 0.529, blue: 0.631, alpha: 0.1)
    )

    /// Foreground color of an error badge or notice.
    static let linkDangerForeground: UIColor = .dynamic(
        light: UIColor(red: 1.0, green: 0.184, blue: 0.298, alpha: 1.0),
        dark: UIColor(red: 1.0, green: 0.184, blue: 0.298, alpha: 1.0)
    )
}

// MARK: - Text color

extension UIColor {

    static let linkPrimaryText: UIColor = .dynamic(
        light: UIColor(red: 0.188, green: 0.192, blue: 0.239, alpha: 1.0),
        dark: .white
    )

    static let linkSecondaryText: UIColor = .dynamic(
        light: UIColor(red: 0.416, green: 0.451, blue: 0.514, alpha: 1.0),
        dark: UIColor(red: 0.922, green: 0.922, blue: 0.961, alpha: 0.6)
    )

    static let linkTertiaryText: UIColor = .dynamic(
        light: UIColor(red: 0.639, green: 0.675, blue: 0.729, alpha: 1.0),
        dark: UIColor(white: 1.0, alpha: 0.38)
    )

}

// MARK: - Icon color

extension UIColor {
    static let linkIconDefault: UIColor = .dynamic(
        light: UIColor(red: 0.216, green: 0.239, blue: 0.282, alpha: 1.0),
        dark: UIColor(red: 0.573, green: 0.573, blue: 0.573, alpha: 1.0)
    )

    static let linkIconBackground: UIColor = .dynamic(
        light: UIColor(red: 0.961, green: 0.965, blue: 0.973, alpha: 1.0),
        dark: UIColor(red: 0.251, green: 0.251, blue: 0.251, alpha: 1.0)
    )

}

// MARK: - Utils

extension UIColor {

    /// Returns the version of the current color that offers the highest contrast when
    /// compared against the given background color and traits.
    ///
    /// - Parameters:
    ///   - backgroundColor: Background color.
    ///   - traitCollection: The base traits to use when resolving the color information.
    /// - Returns: Resolved color that offers the highest contrast ratio.
    func resolvedContrastingColor(
        forBackgroundColor backgroundColor: UIColor,
        traitCollection: UITraitCollection = .current
    ) -> UIColor {
        #if canImport(CompositorServices)
        let resolvedLightModeColor = resolvedColor(with: traitCollection.modifyingTraits({ mutableTraits in
            mutableTraits.userInterfaceStyle = .light
        }))
        let resolvedDarkModeColor = resolvedColor(with: traitCollection.modifyingTraits({ mutableTraits in
            mutableTraits.userInterfaceStyle = .dark
        }))
        #else
        let resolvedLightModeColor = resolvedColor(with: UITraitCollection(traitsFrom: [
            traitCollection,
            UITraitCollection(userInterfaceStyle: .light),
        ]))

        let resolvedDarkModeColor = resolvedColor(with: UITraitCollection(traitsFrom: [
            traitCollection,
            UITraitCollection(userInterfaceStyle: .dark),
        ]))
        #endif

        let resolvedBackgroundColor = backgroundColor.resolvedColor(with: traitCollection)

        let contrastToLightMode = resolvedBackgroundColor.contrastRatio(to: resolvedLightModeColor)
        let contrastToDarkMode = resolvedBackgroundColor.contrastRatio(to: resolvedDarkModeColor)

        return contrastToLightMode > contrastToDarkMode
            ? resolvedLightModeColor
            : resolvedDarkModeColor
    }

}
