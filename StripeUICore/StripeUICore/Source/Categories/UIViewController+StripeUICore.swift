//
//  UIViewController+StripeUICore.swift
//  StripeUICore
//
//  Created by Mel Ludowise on 9/16/21.
//

import UIKit

@_spi(STP) public extension UIViewController {
    /// Use this to animate changes that affect the height of the sheet
    func animateHeightChange(_ animations: (() -> Void)? = nil, completion: ((Bool) -> Void)? = nil)
    {
        // Note: For unknown reasons, using `UIViewPropertyAnimator` here caused an infinite layout loop
        UIView.animate(
            withDuration: 0.5,
            delay: 0,
            usingSpringWithDamping: 1,
            initialSpringVelocity: 0,
            options: [],
            animations: {
                animations?()
                self.rootParent.presentationController?.containerView?.layoutIfNeeded()
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
}
