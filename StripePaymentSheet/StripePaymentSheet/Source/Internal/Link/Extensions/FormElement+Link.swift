//
//  ContainerElement+Link.swift
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
extension ContainerElement {

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
        guard child.view.superview == nil else {
            return
        }
        let heightConstraint = child.view.heightAnchor.constraint(equalToConstant: 0)
        heightConstraint.priority = .required - 1
        NSLayoutConstraint.activate([heightConstraint])
//        child.view.constraints.first { $0.firstAttribute == .height }?.priority = .required - 999
//        child.view.constraints.first { $0.firstAttribute == .height }?.constant = 0
        if animated {
            child.view.alpha = 0
//            self.formView.stackView.addArrangedSubview(child.view)
//            child.view.transform = CGAffineTransform(scaleX: 0.98, y: 0.98).translatedBy(x: 0, y: -10)
//            child.view.superview?.sendSubviewToBack(child.view)
//            child.view.constraints.first { $0.firstAttribute == .height }?.priority = .required
            
            if child.view.superview == nil, let index = self.indexForInsertingElement(child) {
                self.stackView.insertArrangedSubview(child.view, at: index)
            }
//            child.view.transform = CGAffineTransform(scaleX: 0.98, y: 0.98).translatedBy(x: 0, y: -10)
            child.view.superview?.sendSubviewToBack(child.view)
            self.view.setNeedsLayout()
            self.view.layoutIfNeeded()
            UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseOut) {
                heightConstraint.priority = .defaultLow - 1
//                self.formView.stackView.addArrangedSubview(child.view)
    //            child.view.transform = CGAffineTransform(scaleX: 0.98, y: 0.98).translatedBy(x: 0, y: -10)
//                child.view.superview?.sendSubviewToBack(child.view)
                child.view.alpha = 1
//                child.view.transform = .identity
                self.view.setNeedsLayout()
                self.view.layoutIfNeeded()
            } completion: { _ in
                child.view.alpha = 1
                child.view.transform = .identity
            }
        } else {
            if child.view.superview == nil, let index = self.indexForInsertingElement(child) {
                self.stackView.insertArrangedSubview(child.view, at: index)
                self.view.setNeedsLayout()
                self.view.layoutIfNeeded()
            }
        }
    }

    /// Hides a child element with optional animation.
    /// - Parameters:
    ///   - child: Child element to hide.
    ///   - animated: When `true` the transition will be animated.
    func hideChild(_ child: Element, animated: Bool) {
        guard child.view.superview != nil else {
            return
        }

        if animated {
            child.view.alpha = 1
            child.view.transform = .identity
//            child.view.constraints.first { $0.firstAttribute == .height }?.priority = .required - 999
            child.view.superview?.sendSubviewToBack(child.view)
            let heightConstraint = child.view.heightAnchor.constraint(equalToConstant: 0)
            UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseOut) {
                heightConstraint.priority = .required - 1
                heightConstraint.isActive = true
                child.view.alpha = 0
//                child.view.constraints.first { $0.firstAttribute == .height }?.priority = .required
//                snapshot.alpha = 0
//                child.view.transform = CGAffineTransform(scaleX: 0.98, y: 0.98).translatedBy(x: 0, y: -10)
                self.view.setNeedsLayout()
                self.view.layoutIfNeeded()
            } completion: { _ in
                child.view.alpha = 1
                self.stackView.alpha = 1
                heightConstraint.isActive = false
                self.stackView.removeArrangedSubview(child.view)
                child.view.removeFromSuperview()
                child.view.transform = .identity
            }
        } else {
            self.stackView.removeArrangedSubview(child.view)
            child.view.removeFromSuperview()
            self.view.setNeedsLayout()
            self.view.layoutIfNeeded()
        }
    }

}
