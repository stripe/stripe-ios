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
        #if os(visionOS)
        #else
        // Use UIButtonConfiguration for iOS 15+ to avoid deprecated edge inset properties
        if var config = self.configuration {
            // Update existing configuration
            config.contentInsets = edgeInsets
            config.imagePadding = spacing
            self.configuration = config
        } else {
            // Create new configuration if button doesn't have one
            var config = UIButton.Configuration.plain()
            config.contentInsets = edgeInsets
            config.imagePadding = spacing

            // Preserve existing button properties
            if let currentTitle = self.currentTitle {
                config.title = currentTitle
            }
            if let currentImage = self.currentImage {
                config.image = currentImage
            }
            if let currentAttributedTitle = self.currentAttributedTitle {
                config.attributedTitle = AttributedString(currentAttributedTitle)
            }

            self.configuration = config
        }
        #endif
    }

}
