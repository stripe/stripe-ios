//
//  UIFont+Stripe.swift
//  StripeCore
//
//  Created by Yuki Tokuhiro on 11/11/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import Foundation
import UIKit

@_spi(STP) extension UIFont {
    /// The default size category used to compute font size prior to scaling it.
    ///
    /// - seealso:
    /// https://developer.apple.com/documentation/uikit/uifont/scaling_fonts_automatically
    private static let defaultSizeCategory: UIContentSizeCategory = .large

    public static func preferredFont(
        forTextStyle style: TextStyle,
        weight: Weight,
        maximumPointSize: CGFloat? = nil
    ) -> UIFont {
        let metrics = UIFontMetrics(forTextStyle: style)
        let desc = UIFontDescriptor.preferredFontDescriptor(withTextStyle: style)
        let font = UIFont.systemFont(ofSize: desc.pointSize, weight: weight)

        if let maximumPointSize = maximumPointSize {
            return metrics.scaledFont(for: font, maximumPointSize: maximumPointSize)
        }
        return metrics.scaledFont(for: font)
    }

    /// Creates a copy of this `UIFont` with a point size matching the specified style and weight.
    ///
    /// - Parameters:
    ///   - style: The style used to determine the font's size.
    ///   - weight: The weight to apply to the font.
    public func withPreferredSize(
        forTextStyle style: TextStyle,
        weight: Weight? = nil
    ) -> UIFont {
        // Determine the font size for the system default font for this style
        // at the default font scale, apply the size to this font, then return a
        // scaled font using UIFontMetrics.
        //
        // Note: We must scale the font in this way rather than directly using the
        // font size for the current scale, or UILabel won't adjust the font size
        // if the size category dynamically changes.

        // Get font descriptor for the font system default font with this style
        // using the unscaled size category
        let systemDefaultFontDescriptor = UIFontDescriptor.preferredFontDescriptor(
            withTextStyle: style,
            compatibleWith: UITraitCollection(
                preferredContentSizeCategory: UIFont.defaultSizeCategory
            )
        )

        // If no weight was specified, use the weight associated with the system
        // default font for this TextStyle
        var useWeight = weight
        if weight == nil,
            let traits = systemDefaultFontDescriptor.fontAttributes[.traits]
                as? [UIFontDescriptor.TraitKey: Any],
            let systemDefaultWeight = traits[.weight] as? Weight
        {
            useWeight = systemDefaultWeight
        }

        // Create a descriptor that set's the font to the specified weight
        let descriptor = fontDescriptor.addingAttributes([
            .traits: [
                UIFontDescriptor.TraitKey.weight: useWeight,
            ],
        ])

        // Get the point size used by the system font for this style
        let pointSize = systemDefaultFontDescriptor.pointSize

        // Apply the weight and size to the font
        let font = UIFont(descriptor: descriptor, size: pointSize)

        // Scale the font for the current size category
        let metrics = UIFontMetrics(forTextStyle: style)
        return metrics.scaledFont(for: font)
    }
}
