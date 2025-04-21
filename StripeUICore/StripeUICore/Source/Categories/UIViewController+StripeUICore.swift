//
//  UIViewController+StripeUICore.swift
//  StripeUICore
//
//  Created by Mel Ludowise on 9/16/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import UIKit

@_spi(STP) public extension UIViewController {
    /// Use this to animate changes that affect the height of the sheet
    func animateHeightChange(forceAnimation: Bool = false, duration: CGFloat = 0.5, _ animations: (() -> Void)? = nil, postLayoutAnimations: (() -> Void)? = nil, completion: ((Bool) -> Void)? = nil)
    {
        guard forceAnimation || !isBeingPresented else {
            animations?()
            return
        }
        // Note: For unknown reasons, using `UIViewPropertyAnimator` here caused an infinite layout loop
        UIView.animate(
            withDuration: duration,
            delay: 0,
            usingSpringWithDamping: 1,
            initialSpringVelocity: 0,
            options: [],
            animations: {
                animations?()
                self.rootParent.presentationController?.containerView?.layoutIfNeeded()
                postLayoutAnimations?()
            }, completion: { f in
                completion?(f)
            }
        )
    }

    var rootParent: UIViewController {
        if let parent = parent {
            return parent.rootParent
        }
        return self
    }

    /// Returns the topmost view controller in the hierarchy.
    /// - Returns: The topmost `UIViewController`, or `self` if no higher controller is found.
    func findTopMostPresentedViewController() -> UIViewController {
        if let nav = self as? UINavigationController {
            // Use visibleViewController for navigation stacks
            return nav.visibleViewController?.findTopMostPresentedViewController() ?? nav
        } else if let tab = self as? UITabBarController {
            // Use selectedViewController for tab controllers
            return tab.selectedViewController?.findTopMostPresentedViewController() ?? tab
        } else if let presented = presentedViewController {
            // Recurse for any presented controllers
            return presented.findTopMostPresentedViewController()
        }
        
        return self
    }
}
