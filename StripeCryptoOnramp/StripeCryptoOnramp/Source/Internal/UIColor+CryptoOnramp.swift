//
//  UIColor+CryptoOnramp.swift
//  StripeCryptoOnramp
//
//  Created by Michael Liberatore on 9/10/26.
//

@_spi(STP) import StripeUICore
import SwiftUI
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

    /// The background surface for error indicators.
    static let surfaceCritical = UIColor(hex: 0xE61947)

    /// The background surface for success indicators.
    static let surfaceSuccess = UIColor(hex: 0x00D66F)

    /// The foreground color for primary text and icons.
    static let textPrimary = dynamic(light: UIColor(hex: 0x171717), dark: UIColor(hex: 0xFFFFFF))

    /// The foreground color for tertiary text.
    static let textTertiary = dynamic(light: UIColor(hex: 0x707070), dark: UIColor(hex: 0xD4D4D4))

    /// The foreground color on success indicators, kept dark for contrast in both appearances.
    static let textOnSuccess = UIColor(hex: 0x171717)
}

/// Convenience extension for exposing the above semantic colors for SwiftUI usage.
extension Color {
    static let fallbackPrimaryButtonBackground = Color(uiColor: .fallbackPrimaryButtonBackground)
    static let fallbackPrimaryButtonForeground = Color(uiColor: .fallbackPrimaryButtonForeground)
    static let surfacePrimary = Color(uiColor: .surfacePrimary)
    static let surfaceSecondary = Color(uiColor: .surfaceSecondary)
    static let surfaceCritical = Color(uiColor: .surfaceCritical)
    static let surfaceSuccess = Color(uiColor: .surfaceSuccess)
    static let textPrimary = Color(uiColor: .textPrimary)
    static let textTertiary = Color(uiColor: .textTertiary)
    static let textOnSuccess = Color(uiColor: .textOnSuccess)
}

private extension UIColor {
    convenience init(hex: UInt) {
        self.init(red: CGFloat((hex >> 16) & 0xFF) / 255,
                  green: CGFloat((hex >> 8) & 0xFF) / 255,
                  blue: CGFloat(hex & 0xFF) / 255, alpha: 1)
    }
}
