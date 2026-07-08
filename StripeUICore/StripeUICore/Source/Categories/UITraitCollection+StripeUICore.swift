//
//  UITraitCollection+StripeUICore.swift
//  StripeUICore
//
//  Created by Ramon Torres on 10/3/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

@_spi(STP) public extension UITraitCollection {

    var isDarkMode: Bool {
        return userInterfaceStyle == .dark
    }

}
