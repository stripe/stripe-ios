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

    /// Level 400 variant of Link brand color.
    ///
    /// Use for separator bars over the Link brand color.
    static var linkBrand400: UIColor {
        UIColor(red: 0.0, green: 0.64, blue: 0.33, alpha: 1.0)
    }

    /// Color of the Link logo in the navigation bar.
    static let linkNavLogo: UIColor = .dynamic(
        light: UIColor(red: 0.114, green: 0.224, blue: 0.267, alpha: 1.0),
        dark: .white
    )

    /// Foreground color of the primary button.
    static var linkPrimaryButtonForeground: UIColor {
        UIColor(red: 0, green: 0.12, blue: 0.06, alpha: 1.0)
    }

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
