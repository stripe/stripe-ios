//
//  UIButton+Stripe.swift
//  StripePaymentsUI
//
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import UIKit

extension UIButton {
    /// Sets the spacing between the button's image and title label.
    ///
    /// [UIButton: Padding Between Image and Text](https://noahgilmore.com/blog/uibutton-padding/)
    ///
    /// - Parameters:
    ///   - spacing: Space between image and title label.
    ///   - edgeInsets: Directional content edge insets.
    @_spi(STP) public func setContentSpacing(
        _ spacing: CGFloat,
        withEdgeInsets edgeInsets: NSDirectionalEdgeInsets
    ) {
// TODO: Rewrite this for visionOS & iOS 17.
        #if canImport(CompositorServices)
        #else
        // UIButton doesn't have support for directional edge insets. We should
        // apply insets depending on the layout direction.
        if self.effectiveUserInterfaceLayoutDirection == .leftToRight {
            self.imageEdgeInsets = UIEdgeInsets(top: 0, left: -spacing, bottom: 0, right: spacing)
            self.contentEdgeInsets = UIEdgeInsets(
                top: edgeInsets.top,
                left: edgeInsets.leading + spacing,
                bottom: edgeInsets.bottom,
                right: edgeInsets.trailing
            )
        } else {
            self.imageEdgeInsets = UIEdgeInsets(top: 0, left: spacing, bottom: 0, right: -spacing)
            self.contentEdgeInsets = UIEdgeInsets(
                top: edgeInsets.top,
                left: edgeInsets.trailing,
                bottom: edgeInsets.bottom,
                right: edgeInsets.leading + spacing
            )
        }
#endif
    }

}
