//
//  BottomSheetPresentationAnimator.swift
//  StripePaymentSheet
//
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import UIKit

/// Handles the animation of the presentedViewController as it is presented or dismissed.
///
/// This is a vertical animation that
/// - Animates up from the bottom of the screen
/// - Dismisses from the top to the bottom of the screen
@objc(STPBottomSheetPresentationAnimator)
class BottomSheetPresentationAnimator: NSObject {
    enum TransitionStyle {
        case presentation
        case dismissal
    }

    private let transitionStyle: TransitionStyle

    required init(transitionStyle: TransitionStyle) {
        self.transitionStyle = transitionStyle
        super.init()
    }

    private func animatePresentation(transitionContext: UIViewControllerContextTransitioning) {
        guard
            let toVC = transitionContext.viewController(forKey: .to)
        else { return }

        transitionContext.containerView.layoutIfNeeded()

        // Move presented view offscreen (from the bottom)
        toVC.view.frame = transitionContext.finalFrame(for: toVC)
        toVC.view.frame.origin.y = transitionContext.containerView.frame.height

        // Set the work to complete the transition on the BottomSheetViewController.
        // Either we will invoke it in the presentation completion block, 
        // or BottomSheetViewController will invoke it before transitioning to other content
        if let bottomSheetController = toVC as? BottomSheetViewController {
            bottomSheetController.completeBottomSheetPresentationTransition = { [weak bottomSheetController] didComplete in
                transitionContext.completeTransition(didComplete)
                bottomSheetController?.completeBottomSheetPresentationTransition = nil
            }
        }

        Self.animate({
            transitionContext.containerView.setNeedsLayout()
            transitionContext.containerView.layoutIfNeeded()
        }) { didComplete in
            // Complete transition if it hasn't already been completed
            if let bottomSheetController = toVC as? BottomSheetViewController,
               let completePresentationTransition = bottomSheetController.completeBottomSheetPresentationTransition {
                completePresentationTransition(didComplete)
            } else {
                transitionContext.completeTransition(didComplete)
            }
        }
    }

    private func animateDismissal(transitionContext: UIViewControllerContextTransitioning) {
        guard
            let fromVC = transitionContext.viewController(forKey: .from)
        else { return }

        Self.animate({
            fromVC.view.frame.origin.y = transitionContext.containerView.frame.height
        }) { didComplete in
            fromVC.view.removeFromSuperview()
            transitionContext.completeTransition(didComplete)
        }
    }

    static func animate(
        _ animations: @escaping () -> Void,
        _ completion: ((Bool) -> Void)? = nil
    ) {
        let params = UISpringTimingParameters()
        let animator = UIViewPropertyAnimator(duration: 0, timingParameters: params)

        animator.addAnimations(animations)
        if let completion = completion {
            animator.addCompletion { (_) in
                completion(true)
            }
        }
        animator.startAnimation()
    }
}

// MARK: - UIViewControllerAnimatedTransitioning Delegate

extension BottomSheetPresentationAnimator: UIViewControllerAnimatedTransitioning {
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?)
    -> TimeInterval
    {
        // TODO This should depend on height so that velocity is constant
        return 0.5
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        switch transitionStyle {
        case .presentation:
            animatePresentation(transitionContext: transitionContext)
        case .dismissal:
            animateDismissal(transitionContext: transitionContext)
        }
    }
}
