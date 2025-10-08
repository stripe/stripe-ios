//
//  UIResponder+Stripe.swift
//  StripeUICore
//
//  Created by Chris Mays on 3/19/25.
//

import UIKit

@_spi(STP) public extension UIResponder {
    @available(iOSApplicationExtension, unavailable)
    @objc func findViewController() -> UIViewController? {
        if let nextResponder = self.next as? UIViewController {
            return nextResponder
        } else if let nextResponder = self.next {
            return nextResponder.findViewController()
        } else {
            // Can't find a view, attempt to grab the top most view controller
            return UIViewController.topMostViewController()
        }
    }
}
