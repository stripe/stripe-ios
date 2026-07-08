//
//  UIFont+StripeUICore.swift
//  StripeUICore
//
//  Created by Ramon Torres on 11/8/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

@_spi(STP) public extension UIFont {

    func scaled(
        withTextStyle textStyle: UIFont.TextStyle,
        maximumPointSize: CGFloat? = nil,
        compatibleWith traitCollection: UITraitCollection? = nil
    ) -> UIFont {
        let fontMetrics = UIFontMetrics(forTextStyle: textStyle)

        if let maximumFontSize = maximumPointSize {
            return fontMetrics.scaledFont(
                for: self,
                maximumPointSize: maximumFontSize,
                compatibleWith: traitCollection
            )
        }

        return fontMetrics.scaledFont(for: self, compatibleWith: traitCollection)
    }

}
