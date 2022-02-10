//
//  UIFont+Stripe.swift
//  StripeCore
//
//  Created by Yuki Tokuhiro on 11/11/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import Foundation
import UIKit

@_spi(STP) public extension UIFont {
    static func preferredFont(forTextStyle style: TextStyle, weight: Weight, maximumPointSize: CGFloat? = nil) -> UIFont {
        let metrics = UIFontMetrics(forTextStyle: style)
        let desc = UIFontDescriptor.preferredFontDescriptor(withTextStyle: style)
        let font = UIFont.systemFont(ofSize: desc.pointSize, weight: weight)
        
        if let maximumPointSize = maximumPointSize {
            return metrics.scaledFont(for: font, maximumPointSize: maximumPointSize)
        }
        return metrics.scaledFont(for: font)
    }

    /**
     Creates a copy of this `UIFont` with a point size matching the specified style and weight.

     - Parameters:
       - style: The style used to determine the font's size.
       - weight: The weight to apply to the font.
     */
    func withPreferredSize(
        forTextStyle style: TextStyle,
        weight: Weight? = nil
    ) -> UIFont {
        let systemDefaultFontDescriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: style)

        // If no weight was specified, use the weight associated with the system
        // default font for this TextStyle
        var useWeight = weight
        if weight == nil,
           let traits = systemDefaultFontDescriptor.fontAttributes[.traits] as? [UIFontDescriptor.TraitKey: Any],
           let systemDefaultWeight = traits[.weight] as? Weight {
            useWeight = systemDefaultWeight
        }

        // Create a descriptor that set's the font to the specified weight
        let descriptor = fontDescriptor.addingAttributes([.traits: [
            UIFontDescriptor.TraitKey.weight: useWeight
        ]])

        // Get the point size used by the system font for this style
        let pointSize = systemDefaultFontDescriptor.pointSize

        // Apply the weight and size to the font
        let font = UIFont(descriptor: descriptor, size: pointSize)

        // Return scaled font
        let metrics = UIFontMetrics(forTextStyle: style)
        return metrics.scaledFont(for: font)
    }
}
