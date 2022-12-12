//
//  UIStackView+StripeUICore.swift
//  StripeUICore
//
//  Created by Ramon Torres on 10/22/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import UIKit

// MARK: - Animation utilities

@_spi(STP) public extension UIStackView {

    /// Hides an arranged subview with optional animation.
    ///
    /// - Parameters:
    ///   - index: The index of the arranged subview to hide.
    ///   - animated: Whether or not to animate the transition.
    func showArrangedSubview(at index: Int, animated: Bool) {
        let view = arrangedSubviews[index]
        toggleArrangedSubview(view, shouldShow: true, animated: animated)
    }

    /// Hides an arranged subview with optional animation.
    ///
    /// - Parameters:
    ///   - index: The index of the arranged subview to hide.
    ///   - animated: Whether or not to animate the transition.
    func hideArrangedSubview(at index: Int, animated: Bool) {
        let view = arrangedSubviews[index]
        toggleArrangedSubview(view, shouldShow: false, animated: animated)
    }

    /// Toggles the visibility of an arranged subview with optional animation.
    ///
    /// - Parameters:
    ///   - view: Arranged subview to update.
    ///   - shouldShow: Whether or not to show the view.
    ///   - animated: Whether or not to animate the transition.
    func toggleArrangedSubview(_ view: UIView, shouldShow: Bool, animated: Bool) {
        toggleArrangedSubviews([view], shouldShow: shouldShow, animated: animated)
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
        toggleArrangedSubviews([view], shouldShow: false, animated: animated) { _ in
            view.removeFromSuperview()
            view.isHidden = false
            view.alpha = 1
            completion?()
        }
    }

    // MARK: - Helpers

    /// Toggles the visibility of arranged subviews with animation.
    ///
    /// This method enhances the default constraint based animation by adding fade-in/out as
    /// secondary action. Making the animation more correct.
    ///
    /// - Parameters:
    ///   - views: The arranged subviews to be toggled.
    ///   - shouldShow: Whether or not it should show the views.
    ///   - animated: Whether or not to animate the transition.
    ///   - completion: A block to be called when the animation finishes.
    func toggleArrangedSubviews(
        _ views: [UIView],
        shouldShow: Bool,
        animated: Bool,
        completion: ((Bool) -> Void)? = nil
    ) {
        let viewsToUpdate = views.filter { $0.isHidden == shouldShow }

        if animated {
            let outTransform = CGAffineTransform(translationX: 0, y: -10)

            viewsToUpdate.forEach { view in
                view.isHidden = shouldShow
                view.alpha = shouldShow ? 0 : 1
                view.transform = shouldShow ? outTransform : .identity
            }

            UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseOut) {
                viewsToUpdate.forEach { view in
                    view.isHidden = !shouldShow
                    view.alpha = shouldShow ? 1 : 0
                    view.transform = shouldShow ? .identity : outTransform
                }

                self.setNeedsLayout()
                self.layoutIfNeeded()
            } completion: { done in
                viewsToUpdate.forEach { view in
                    view.transform = .identity
                }

                completion?(done)
            }
        } else {
            viewsToUpdate.forEach { view in
                view.isHidden = !shouldShow
            }
        }
    }

}
