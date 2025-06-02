//
//  UIViewController+StripeConnect.swift
//  StripeConnect
//
//  Created by Mel Ludowise on 10/11/24.
//

@_spi(STP) import StripeUICore

#if canImport(UIKit) && !os(macOS)
import UIKit
#elseif canImport(AppKit) && os(macOS)
import AppKit
#endif

extension StripeViewController {
    /// Helper that adds a child view controller and pins its view to this view controller's view
    func addChildAndPinView(_ child: StripeViewController) {
        #if canImport(UIKit) && !os(macOS)
        child.willMove(toParent: self)
        addChild(child)
        stripeView.addAndPinSubview(child.stripeView)
        child.didMove(toParent: self)
        #elseif canImport(AppKit) && os(macOS)
        addChild(child)
        stripeView.addAndPinSubview(child.stripeView)
        #endif
    }
}
