//
//  UIActivityIndicatorView+Stripe.swift
//  StripeCore
//
//  Created by Mel Ludowise on 3/9/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import UIKit

@_spi(STP) extension UIActivityIndicatorView {
    #if DEBUG
        /// Disables animation for `stp_startAnimatingAndShow`.
        ///
        /// This should be disabled in snapshot tests.
        public static var stp_isAnimationEnabled = true
    #endif

    /// This method should be used in place of `hidesWhenStopped` and `startAnimating()`
    /// so we can ensure consistency in snapshot tests.
    public func stp_startAnimatingAndShow() {
        isHidden = false
        #if DEBUG
            guard UIActivityIndicatorView.stp_isAnimationEnabled else { return }
        #endif
        startAnimating()
    }

    /// This method should be used in place of  and `hidesWhenStopped` and `stopAnimating()`
    /// so we can ensure consistency in snapshot tests.
    public func stp_stopAnimatingAndHide() {
        isHidden = true
        stopAnimating()
    }
}
