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

    /// Walks the presented view controller hierarchy and return the top most presented controller.
    /// - Returns: Returns the top most presented view controller, or `nil` if this view controller is not presenting another controller.
    func findTopMostPresentedViewController() -> UIViewController? {
        var topMostController = self.presentedViewController

        while let presented = topMostController?.presentedViewController {
            topMostController = presented
        }

        return topMostController
    }
}
