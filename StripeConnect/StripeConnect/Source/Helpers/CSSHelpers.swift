//
//  CSSHelpers.swift
//  StripeConnect
//
//  Created by Chris Mays on 8/28/24.
//

import UIKit

extension CGFloat {
    var pxString: String {
        "\(Int(self))px"
    }
}

extension UIFont.Weight {
    
    // https://developer.mozilla.org/en-US/docs/Web/CSS/font-weight#common_weight_name_mapping
    static var stringMappings: [UIFont.Weight: String] {
        [
            .thin: "100",
            .ultraLight: "200",
            .light: "300",
            .regular: "400",
            .medium: "500",
            .semibold: "600",
            .bold: "700",
            .heavy: "800",
            .black: "900"
        ]
    }
    
    var cssValue: String? {
        UIFont.Weight.stringMappings[self]
    }
}

// TODO: MXMOBILE-2753 Move this to StripeCore.
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
    
    var cssRgbaValue: String {
        cssValue(includeAlpha: true)
    }
    
    var cssRgbValue: String {
        cssValue(includeAlpha: false)
    }
}
