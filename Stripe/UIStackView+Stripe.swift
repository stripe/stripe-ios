//
//  UIStackView+Stripe.swift
//  StripeiOS
//
//  Created by Ramon Torres on 10/22/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import UIKit

// MARK: - Animation utilities

extension UIStackView {

    /// Hides an arranged subview with optional animation.
    ///
    /// - Parameters:
    ///   - index: The index of the arranged subview to hide.
    ///   - animated: Whether or not to animate the transition.
    func showArrangedSubview(at index: Int, animated: Bool) {
        let view = arrangedSubviews[index]
        toggleArrangedSubviews([view], shouldShow: true)
    }

    /// Hides an arranged subview with optional animation.
    ///
    /// - Parameters:
    ///   - index: The index of the arranged subview to hide.
    ///   - animated: Whether or not to animate the transition.
    func hideArrangedSubview(at index: Int, animated: Bool) {
        let view = arrangedSubviews[index]
        toggleArrangedSubviews([view], shouldShow: false)
    }

    /// Removes an arranged subview at a given index.
    ///
    /// - Parameters:
    ///   - index: The index of the arranged subview to be removed.
    ///   - animated: Whether or not to animate the removal.
    ///   - completion: A block to be called after removing the view.
    func removeArrangedSubview(at index: Int, animated: Bool, completion: (() -> Void)? = nil) {
        removeArrangedSubview(arrangedSubviews[index], animated: animated, completion: completion)
    }

    /// Removes the provided view from the arranged subviews with an animation.
    ///
    /// - Parameters:
    ///   - view: The view to be removed from the array of views arranged by the stack.
    ///   - animated: Whether or not to animate the removal.
    ///   - completion: A block to be called after removing the view.
    func removeArrangedSubview(_ view: UIView, animated: Bool, completion: (() -> Void)? = nil) {
        let removeBlock = {
            view.removeFromSuperview()
            view.isHidden = false
            view.alpha = 1
        }

        if animated {
            toggleArrangedSubviews([view], shouldShow: false) { _ in
                removeBlock()
                completion?()
            }
        } else {
            removeBlock()
            completion?()
        }
    }

    /// Toggles the visibility of arranged subviews with animation.
    ///
    /// This method enhances the default constraint based animation by adding fade-in/out as
    /// secondary action. Making the animation more correct.
    ///
    /// - Parameters:
    ///   - views: The arranged subviews to be toggled.
    ///   - shouldShow: Wheter or not it should show the views.
    ///   - completion: A block to be called when the animation finishes.
    func toggleArrangedSubviews(
        _ views: [UIView],
        shouldShow: Bool,
        completion: ((Bool) -> Void)? = nil
    ) {
        let viewsToAnimate = views.filter { $0.isHidden == shouldShow }

        viewsToAnimate.forEach { view in
            view.isHidden = shouldShow
            view.alpha = shouldShow ? 0 : 1
        }

        UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseOut) {
            viewsToAnimate.forEach { view in
                view.isHidden = !shouldShow
                view.alpha = shouldShow ? 1 : 0
            }
        } completion: { done in
            completion?(done)
        }
    }

}
