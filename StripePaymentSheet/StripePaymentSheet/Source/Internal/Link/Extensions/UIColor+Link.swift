//
//  UIColor+Link.swift
//  StripePaymentSheet
//
//  Created by Ramon Torres on 11/1/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//
@_spi(STP) import StripeUICore
import UIKit

// MARK: - Custom colors

extension UIColor {

    // MARK: - Semantic Colors

    // Surface colors
    static let linkSurfacePrimary: UIColor = dynamic(light: neutral0, dark: neutral900)
    static let linkSurfaceSecondary: UIColor = dynamic(light: neutral100, dark: neutral800)
    static let linkSurfaceTertiary: UIColor = dynamic(light: neutral200, dark: neutral700)

    // Border colors
    static let linkBorderDefault: UIColor = dynamic(light: neutral300, dark: neutral900)
    static let linkBorderSelected: UIColor = dynamic(light: neutral900, dark: brand200)

    // Button colors
    static let linkButtonBrand: UIColor = brand200

    // Text colors
    static let linkTextPrimary: UIColor = dynamic(light: neutral900, dark: neutral0)
    static let linkTextSecondary: UIColor = dynamic(light: neutral700, dark: neutral300)
    static let linkTextTertiary: UIColor = neutral500
    static let linkTextBrand: UIColor = dynamic(light: brand600, dark: brand200)
    static let linkTextCritical: UIColor = critical600

    // Icon colors
    static let linkIconPrimary: UIColor = dynamic(light: neutral900, dark: neutral100)
    static let linkIconTertiary: UIColor = neutral500
    static let linkIconBrand: UIColor = brand200
    static let linkIconCritical: UIColor = critical500

    /**
     * Workaround:
     *
     * - The new Link theme primary button uses white on dark mode and dark on light mode
     * - But we're still using Link green theming for buttons, regardless of dark mode
     * - This means that the fixed button color is not consistent with variable text / divider colors,
     *   so we need to keep them fixed until we migrate to the updated primary color styling.
     */
    /// Content color on primary button
    static let linkContentOnPrimaryButton: UIColor = UIColor(red: 0, green: 0.12, blue: 0.06, alpha: 1.0)
    /// Separator color on primary button
    static let linkSeparatorOnPrimaryButton: UIColor = brand400
    /// Foreground color in the outlined Link hint message view
    static let linkOutlinedHintMessageForeground: UIColor = .dynamic(light: neutral700, dark: neutral500)
    /// Border color around the outlined Link hint message view
    static let linkOutlinedHintMessageBorder: UIColor = .dynamic(light: neutral300, dark: neutral500)

    /**
     * Workaround:
     *
     * Border color doesn't look great for radio buttons on dark mode. We give it a clearer
     * color here.
     *
     */
    static let linkRadioButtonUnselectedColor: UIColor = .dynamic(light: linkBorderDefault, dark: neutral700)

    /**
     * Workaround:
     *
     * Tertiary text color doesn't look great on this badge in dark mode. We give it a lighter color here.
     *
     */
    static let linkBadgeNeutralForegroundColor: UIColor = dynamic(light: linkTextTertiary, dark: neutral400)

    /**
     * Workaround:
     *
     * We use a custom background color for toasts, and a white foreground color.
     *
     */
    static let linkToastForeground: UIColor = neutral0
    static let linkToastBackground: UIColor = brand900

    static let linkExpressCheckoutButtonDivider: UIColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.12)
    static let linkExpressCheckoutButtonForeground: UIColor = UIColor(red: 13/255, green: 13/255, blue: 13/255, alpha: 1)
    static let linkExpressCheckoutButtonBackground: UIColor = .white
}

private extension UIColor {

    // MARK: - Raw Colors
    /**
     * Workaround:
     *
     * When migrating from RGB to their equivalent HEX colors, there were some very minor differences with the
     * new HEX colors. We decided to keep the original RGB colors for some of the more widely-used Link colors
     * (i.e. those used in `PayWithLinkButton`).
     */

    static let neutral900: UIColor = UIColor(red: 0.11, green: 0.11, blue: 0.118, alpha: 1.0) // #171717
    static let neutral800: UIColor = UIColor(hex: 0x262626)
    static let neutral700: UIColor = UIColor(hex: 0x404040)
    static let neutral500: UIColor = UIColor(hex: 0x707070)
    static let neutral400: UIColor = UIColor(hex: 0xA3A3A3)
    static let neutral300: UIColor = UIColor(hex: 0xD4D4D4)
    static let neutral200: UIColor = UIColor(hex: 0xE5E5E5)
    static let neutral100: UIColor = UIColor(hex: 0xF5F5F5)
    static let neutral0: UIColor = UIColor(hex: 0xFFFFFF)
    static let brand900: UIColor = UIColor(hex: 0x30303D)
    static let brand600: UIColor = UIColor(hex: 0x006635)
    static let brand400: UIColor = UIColor(red: 0, green: 0.64, blue: 0.33, alpha: 1.0) // #00A355
    static let brand200: UIColor = UIColor(red: 0, green: 0.84, blue: 0.44, alpha: 1.0) // #00D670
    static let critical600: UIColor = UIColor(hex: 0xC0123C)
    static let critical500: UIColor = UIColor(hex: 0xE61947)
}

// MARK: - Utils

extension UIColor {

    /// Helper to initialize UIColor with a hex value
    convenience init(hex: UInt) {
        let red = CGFloat((hex >> 16) & 0xFF) / 255.0
        let green = CGFloat((hex >> 8) & 0xFF) / 255.0
        let blue = CGFloat(hex & 0xFF) / 255.0
        self.init(red: red, green: green, blue: blue, alpha: 1.0)
    }

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
        #if os(visionOS)
        let resolvedLightModeColor = resolvedColor(
            with: traitCollection.modifyingTraits({ mutableTraits in
                mutableTraits.userInterfaceStyle = .light
            })
        )
        let resolvedDarkModeColor = resolvedColor(
            with: traitCollection.modifyingTraits({ mutableTraits in
                mutableTraits.userInterfaceStyle = .dark
            })
        )
        #else
        let resolvedLightModeColor = resolvedColor(
            with: UITraitCollection(traitsFrom: [
                traitCollection,
                UITraitCollection(userInterfaceStyle: .light),
            ])
        )
        let resolvedDarkModeColor = resolvedColor(
            with: UITraitCollection(traitsFrom: [
                traitCollection,
                UITraitCollection(userInterfaceStyle: .dark),
            ])
        )
        #endif

        let resolvedBackgroundColor = backgroundColor.resolvedColor(with: traitCollection)
        let contrastToLightMode = resolvedBackgroundColor.contrastRatio(to: resolvedLightModeColor)
        let contrastToDarkMode = resolvedBackgroundColor.contrastRatio(to: resolvedDarkModeColor)
        return contrastToLightMode > contrastToDarkMode
            ? resolvedLightModeColor
            : resolvedDarkModeColor
    }
}
