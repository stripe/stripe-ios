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
    ///   - fontSize: Optional font size to override the default font size provided by the `UIFont.TextStyle` before scaling
    /// - Returns: A font scaled to be used in PaymentSheet
    /// - Note: To prevent the font from being scaled down, set `minimumContentSizeCategory = .large` on the label.
    func scaledFont(for font: UIFont, style: UIFont.TextStyle, maximumPointSize: CGFloat, fontSize: CGFloat? = nil) -> UIFont {
        let defaultTraitCollection = UITraitCollection(preferredContentSizeCategory: .large) // large is the default content size category
        let fontDescriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: style, compatibleWith: defaultTraitCollection)
        if let fontSize {
            // If present override the font size on the descriptor before scaling for dynamic type happens below
            fontDescriptor.withSize(fontSize)
        }
        let customFont = font.withSize(fontDescriptor.pointSize * self.font.sizeScaleFactor)

        // scale the custom font for dynamic type
        return UIFontMetrics.default.scaledFont(for: customFont, maximumPointSize: maximumPointSize)
    }
}
