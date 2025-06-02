//
//  UIWindow+Stripe.swift
//  StripePaymentSheet
//
//  Created by Ramon Torres on 2/3/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

#if canImport(UIKit) && !os(macOS)
import UIKit

@_spi(STP) public extension UIWindow {

    /// Returns the top most presented view controller including the root view controller.
    /// - Returns: The top most view controller, or `nil` if the window has no root view controller.
    func findTopMostPresentedViewController() -> UIViewController? {
        return self.rootViewController?.findTopMostPresentedViewController()
            ?? self.rootViewController
    }

}

#elseif canImport(AppKit) && os(macOS)
import AppKit

@_spi(STP) public extension NSWindow {

    /// Returns the top most presented view controller including the root view controller.
    /// - Returns: The top most view controller, or `nil` if the window has no root view controller.
    func findTopMostPresentedViewController() -> NSViewController? {
        return self.contentViewController?.findTopMostPresentedViewController()
            ?? self.contentViewController
    }

}

#endif
