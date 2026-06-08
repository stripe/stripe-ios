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
    /// - Parameters:
    ///   - spacing: Space between image and title label.
    ///   - edgeInsets: Directional content edge insets.
    @_spi(STP) public func setContentSpacing(
        _ spacing: CGFloat,
        withEdgeInsets edgeInsets: NSDirectionalEdgeInsets
    ) {
        var config = self.configuration ?? .plain()
        config.imagePadding = spacing
        config.contentInsets = edgeInsets
        self.configuration = config
    }

}
