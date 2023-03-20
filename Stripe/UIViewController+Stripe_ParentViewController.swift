//
//  UIViewController+Stripe_ParentViewController.swift
//  Stripe
//
//  Created by Jack Flintermann on 1/12/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

import UIKit

extension UIViewController {
    @objc(stp_parentViewControllerOfClass:) func stp_parentViewControllerOf(_ klass: AnyClass)
        -> UIViewController?
    {
        if let parent = parent, parent.isKind(of: klass) {
            return parent
        }
        return parent?.stp_parentViewControllerOf(klass)
    }

    @objc func stp_isTopNavigationController() -> Bool {
        return navigationController?.topViewController == self
    }

    @objc func stp_isAtRootOfNavigationController() -> Bool {
        let viewController = navigationController?.viewControllers.first
        var tested: UIViewController? = self
        while tested != nil {
            if tested == viewController {
                return true
            }
            if let parent = tested?.parent {
                tested = parent
            } else {
                return false
            }
        }
        return false
    }

    @objc func stp_previousViewControllerInNavigation() -> UIViewController? {
        let index = navigationController?.viewControllers.firstIndex(of: self) ?? NSNotFound
        if index == NSNotFound || index <= 0 {
            return nil
        }
        return navigationController?.viewControllers[index - 1]
    }
}
