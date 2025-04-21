//
//  Appearance+FontScaling.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 3/15/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import UIKit

extension PaymentSheet.Appearance {

    /// Computes a font scaled to be used in PaymentSheet
    /// - Parameters:
    ///   - font: The font to be scaled
    ///   - style: The style for your text
    ///   - maximumPointSize: The maximum font size to be scaled to
    /// - Returns: A font scaled to be used in PaymentSheet
    /// - Note: To prevent the font from being scaled down, set `minimumContentSizeCategory = .large` on the label.
    func scaledFont(for font: UIFont, style: UIFont.TextStyle, maximumPointSize: CGFloat) -> UIFont {
        let defaultTraitCollection = UITraitCollection(preferredContentSizeCategory: .large) // large is the default content size category
        let fontDescriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: style, compatibleWith: defaultTraitCollection)
        let customFont = font.withSize(fontDescriptor.pointSize * self.font.sizeScaleFactor)

        // scale the custom font for dynamic type
        return UIFontMetrics.default.scaledFont(for: customFont, maximumPointSize: maximumPointSize)
    }

    /// Computes a font scaled to be used in PaymentSheet
    /// - Parameters:
    ///   - font: The font to be scaled
    ///   - size: The size of the font
    ///   - maximumPointSize: The maximum font size to be scaled to
    /// - Returns: A font scaled to be used in PaymentSheet
    /// - Note: To prevent the font from being scaled down, set `minimumContentSizeCategory = .large` on the label.
    func scaledFont(for font: UIFont, size: CGFloat, maximumPointSize: CGFloat) -> UIFont {
        let customFont = font.withSize(size * self.font.sizeScaleFactor)

        // scale the custom font for dynamic type
        return UIFontMetrics.default.scaledFont(for: customFont, maximumPointSize: maximumPointSize)
    }
}
