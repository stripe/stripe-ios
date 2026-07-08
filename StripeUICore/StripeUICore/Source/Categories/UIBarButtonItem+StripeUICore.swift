//
//  UIBarButtonItem+StripeUICore.swift
//  StripeUICore
//
//  Created by Ramon Torres on 10/4/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

@_spi(STP) public extension UIBarButtonItem {

    /// Creates a new flexible width space item.
    ///
    /// Backport for iOS < 14.0
    /// - Returns: A flexible-width space UIBarButtonItem.
    class func flexibleSpace() -> Self {
        return .init(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
    }

}
