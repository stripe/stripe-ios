//
//  FormElement+Link.swift
//  StripePaymentSheet
//
//  Created by Ramon Torres on 1/20/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

@_spi(STP) import StripeUICore
import UIKit

// TODO(ramont): Graduate to StripeUICore.

/// Animation utilities
///
/// Provides better animations than default `UIStackView` arranged subview visibility toggles.
extension FormElement {

    /// Toggles the visibility of a child element.
    /// - Parameters:
    ///   - child: Child element.
    ///   - show: Whether to show or hide the child element.
    ///   - animated: When `true`, the visibility toggle will be performed with animation.
    func toggleChild(_ child: Element, show: Bool, animated: Bool) {
        if show {
            showChild(child, animated: animated)
        } else {
            hideChild(child, animated: animated)
        }
    }

    /// Shows a child element with optional animation.
    /// - Parameters:
    ///   - child: Child element to show.
    ///   - animated: When `true` the transition will be animated.
    func showChild(_ child: Element, animated: Bool) {
        guard child.view.isHidden else {
            return
        }

        if animated {
            child.view.alpha = 0
            child.view.transform = CGAffineTransform(scaleX: 0.98, y: 0.98).translatedBy(x: 0, y: -10)
            child.view.superview?.sendSubviewToBack(child.view)
            UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseOut) {
                child.view.alpha = 1
                child.view.isHidden = false
                child.view.transform = .identity
                self.view.setNeedsLayout()
                self.view.layoutIfNeeded()
            } completion: { _ in
                child.view.alpha = 1
                child.view.isHidden = false
                child.view.transform = .identity
            }
        } else {
            child.view.isHidden = false
        }
    }

    /// Hides a child element with optional animation.
    /// - Parameters:
    ///   - child: Child element to hide.
    ///   - animated: When `true` the transition will be animated.
    func hideChild(_ child: Element, animated: Bool) {
        guard !child.view.isHidden else {
            return
        }

        if animated {
            child.view.alpha = 1
            child.view.transform = .identity
            child.view.superview?.sendSubviewToBack(child.view)
            UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseOut) {
                child.view.alpha = 0
                child.view.isHidden = true
                child.view.transform = CGAffineTransform(scaleX: 0.98, y: 0.98).translatedBy(x: 0, y: -10)
                self.view.setNeedsLayout()
                self.view.layoutIfNeeded()
            } completion: { _ in
                child.view.alpha = 1
                child.view.isHidden = true
                child.view.transform = .identity
            }
        } else {
            child.view.isHidden = true
        }
    }

}
