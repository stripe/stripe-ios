//
//  UIColor+CryptoOnramp.swift
//  StripeCryptoOnramp
//
//  Created by Michael Liberatore on 9/10/26.
//

@_spi(STP) import StripeUICore
import UIKit

extension UIColor {

    /// The fallback primary button background color when no appearance override is supplied.
    static let fallbackPrimaryButtonBackground = UIColor(hex: 0x00D670)

    /// The fallback primary button foreground color when no appearance override is supplied.
    static let fallbackPrimaryButtonForeground = UIColor(hex: 0x001F0F)

    /// The primary background surface.
    static let surfacePrimary = dynamic(light: UIColor(hex: 0xFFFFFF), dark: UIColor(hex: 0x1C1C1E))

    /// The secondary surface used behind icons and controls.
    static let surfaceSecondary = dynamic(light: UIColor(hex: 0xF5F5F5), dark: UIColor(hex: 0x262626))

    /// The foreground color for primary text and icons.
    static let textPrimary = dynamic(light: UIColor(hex: 0x171717), dark: UIColor(hex: 0xFFFFFF))

    /// The foreground color for tertiary text.
    static let textTertiary = dynamic(light: UIColor(hex: 0x707070), dark: UIColor(hex: 0xD4D4D4))

    /// The background surface for error indicators.
    static let surfaceCritical = UIColor(hex: 0xE61947)
}

private extension UIColor {
    convenience init(hex: UInt) {
        self.init(red: CGFloat((hex >> 16) & 0xFF) / 255,
                  green: CGFloat((hex >> 8) & 0xFF) / 255,
                  blue: CGFloat(hex & 0xFF) / 255, alpha: 1)
    }
}
