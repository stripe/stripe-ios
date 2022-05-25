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
         let params = UISpringTimingParameters()
         let animator = UIViewPropertyAnimator(duration: 0, timingParameters: params)

         if let animations = animations {
             animator.addAnimations(animations)
         }
         animator.addAnimations {
             // Unless we lay out the container view, the layout jumps
             self.rootParent.presentationController?.containerView?.layoutIfNeeded()
         }
         if let completion = completion {
             animator.addCompletion { _ in
                 completion(true)
             }
         }
         animator.startAnimation()
     }

     var rootParent: UIViewController {
         if let parent = parent {
             return parent.rootParent
         }
         return self
     }
}
