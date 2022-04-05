//
//  UIColor+Stripe.swift
//  StripeiOS
//
//  Created by Yuki Tokuhiro on 11/16/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import Foundation
import UIKit

extension UIColor {

    /// The relative luminance of the color.
    ///
    /// # Reference
    ///
    /// * [Relative Luminance](https://en.wikipedia.org/wiki/Relative_luminance)
    /// * [WCAG 2.2 specification](https://www.w3.org/TR/WCAG21/#dfn-relative-luminance)
    ///
    var luminance: CGFloat {
        var sr: CGFloat = 0
        var sg: CGFloat = 0
        var sb: CGFloat = 0

        // get the (extended) sRGB components
        getRed(&sr, green: &sg, blue: &sb, alpha: nil)

        // Convert from sRGB to linear RGB
        let r = sr < 0.04045 ? sr / 12.92 : pow((sr + 0.055) / 1.055, 2.4)
        let g = sg < 0.04045 ? sg / 12.92 : pow((sg + 0.055) / 1.055, 2.4)
        let b = sb < 0.04045 ? sb / 12.92 : pow((sb + 0.055) / 1.055, 2.4)

        // Calculate luminance (Y)
        let y = r * 0.2126 + g * 0.7152 + b * 0.0722

        return min(max(y, 0), 1)
    }

    /// Calculates the contrast ratio to another color as defined by WCAG 2.1.
    ///
    /// The resulting ratios can range from 1 to 21.
    ///
    /// # Reference
    ///
    /// [WCAG 2.1 Contrast Ratio spec](https://www.w3.org/WAI/WCAG21/Understanding/contrast-minimum.html#dfn-contrast-ratio)
    ///
    /// - Parameter other: Color to calculate the contrast against.
    /// - Returns: Contrast ratio.
    func contrastRatio(to other: UIColor) -> CGFloat {
        let luminanceA = self.luminance
        let luminanceB = other.luminance
        return (max(luminanceA, luminanceB) + 0.05) / (min(luminanceA, luminanceB) + 0.05)
    }
    
    /// Returns a contrasting color to this color
    /// - Returns: Either white or black color depending on which will contrast best with this color
    var contrastingColor: UIColor {
        let contrastRatioToWhite = contrastRatio(to: .white)
        let contrastRatioToBlack = contrastRatio(to: .black)
        
        var isDarkMode = false
        if #available(iOS 13.0, *) {
            isDarkMode =  UITraitCollection.current.userInterfaceStyle == .dark
        }
        
        // Prefer using a white foreground as long as a minimum contrast threshold is met.
        // Factor the container color to compensate for "local adaptation".
        // https://github.com/w3c/wcag/issues/695
        let threshold: CGFloat = isDarkMode ? 3.6 : 2.2
        if contrastRatioToWhite > threshold {
            return .white
        }
        
        // Pick the foreground color that offers the best contrast ratio
        return contrastRatioToWhite > contrastRatioToBlack ? .white : .black
    }
    
    /// Returns this color in a "disabled" state by reducing the alpha by 40%
    var disabledColor: UIColor {
        return self.withAlphaComponent(0.6)
    }
}
