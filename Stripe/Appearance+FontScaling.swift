//
//  Appearance+FontScaling.swift
//  StripeiOS
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
    func scaledFont(for font: UIFont, style: UIFont.TextStyle, maximumPointSize: CGFloat) -> UIFont {
        let defaultTraitCollection = UITraitCollection(preferredContentSizeCategory: .large) // large is the default content size category
        let fontDescriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: style, compatibleWith: defaultTraitCollection)
        let customFont = font.withSize(fontDescriptor.pointSize * self.font.sizeScaleFactor)
        
        // scale the custom font for dynamic type
        return UIFontMetrics.default.scaledFont(for: customFont, maximumPointSize: maximumPointSize)
    }
}
