//
//  UIColor+CSS.swift
//  StripeCore
//
//  Created by Mel Ludowise on 5/2/24.
//

import UIKit

extension UIColor {
    func cssValue(includeAlpha: Bool) -> String {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 1

        getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        if includeAlpha {
            return String(
                format: "rgba(%.0f, %.0f, %.0f, %f)",
                red * 255,
                green * 255,
                blue * 255,
                alpha
            )
        } else {
            return String(
                format: "rgb(%.0f, %.0f, %.0f)",
                red * 255,
                green * 255,
                blue * 255
            )
        }
    }

    @_spi(STP) public var cssRgbaValue: String {
        cssValue(includeAlpha: true)
    }

    @_spi(STP) public var cssRgbValue: String {
        cssValue(includeAlpha: false)
    }
}
