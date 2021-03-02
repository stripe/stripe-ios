//
//  UIView+Stripe_SafeAreaBounds.swift
//  Stripe
//
//  Created by Ben Guo on 12/12/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

import UIKit

extension UIView {
    /// Returns this view's bounds inset to `safeAreaInsets.left` and `safeAreaInsets.right`.
    /// Top and bottom safe area insets are ignored. On iOS <11, this returns self.bounds.
    @objc func stp_boundsWithHorizontalSafeAreaInsets() -> CGRect {
        let insets = safeAreaInsets
        let safeBounds = CGRect(
            x: bounds.origin.x + insets.left,
            y: bounds.origin.y,
            width: bounds.size.width - (insets.left + insets.right),
            height: bounds.size.height)
        return safeBounds
    }
}
