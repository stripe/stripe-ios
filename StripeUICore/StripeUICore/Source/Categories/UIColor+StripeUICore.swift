//
//  UIColor+StripeUICore.swift
//  StripeUICore
//
//  Created by Ramon Torres on 11/8/21.
//

import UIKit

@_spi(STP) public extension UIColor {

    /// Increases the brightness of the color by the given `amount`.
    ///
    /// The brightness of the resulting color will be clamped to a max value of`1.0`.
    /// - Parameter amount: Adjustment amount (range: 0.0 - 1.0.)
    /// - Returns: Adjusted color.
    func lighten(by amount: CGFloat) -> UIColor {
        return byModifyingBrightness { min($0 + amount, 1) }
    }

    /// Decreases the brightness of the color by the given `amount`.
    ///
    /// The brightness of the resulting color will be clamped to a min value of`0.0`.
    /// - Parameter amount: Adjustment amount (range: 0.0 - 1.0.)
    /// - Returns: Adjusted color.
    func darken(by amount: CGFloat) -> UIColor {
        return byModifyingBrightness { max($0 - amount, 0) }
    }

    static func dynamic(light: UIColor, dark: UIColor) -> UIColor {
        if #available(iOS 13.0, *) {
            return UIColor(dynamicProvider: {
                switch $0.userInterfaceStyle {
                case .light, .unspecified:
                    return light
                case .dark:
                    return dark
                @unknown default:
                    return light
                }
            })
        }
        return light
    }

}

// MARK: - Helpers

private extension UIColor {

    /// Transforms the brightness and returns the resulting color.
    ///
    /// - Parameter transform: A block for transforming the brightness.
    /// - Returns: Updated color.
    func byModifyingBrightness(_ transform: @escaping (CGFloat) -> CGFloat) -> UIColor {
        // Similar to `UIColor.withAlphaComponent()`, the returned color must be dynamic. This ensures
        // that the color automatically adapts between light and dark mode.
        return .dynamic { _ in
            var hue: CGFloat = 0
            var saturation: CGFloat = 0
            var brightness: CGFloat = 0
            var alpha: CGFloat = 0

            self.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)

            return UIColor(
                hue: hue,
                saturation: saturation,
                brightness: transform(brightness),
                alpha: alpha
            )
        }
    }

    static func dynamic(_ provider: @escaping (UITraitCollection?) -> UIColor) -> UIColor {
        if #available(iOS 13.0, *) {
            return UIColor(dynamicProvider: { provider($0) })
        } else {
            return provider(nil)
        }
    }

}
