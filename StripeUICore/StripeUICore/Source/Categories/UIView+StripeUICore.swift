//
//  UIView+StripeUICore.swift
//  StripeUICore
//
//  Created by Mel Ludowise on 9/16/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation
import UIKit

@_spi(STP) public extension UIView {
    /// - Note: This variant of `addAndPinSubview` respects the view's `directionalLayoutMargins` property.
    /// This is useful if your margins can change dynamically.
    func addAndPinSubview(_ view: UIView, directionalLayoutMargins: NSDirectionalEdgeInsets) {
        self.directionalLayoutMargins = directionalLayoutMargins
        view.translatesAutoresizingMaskIntoConstraints = false
        addSubview(view)

        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
            view.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor),
            view.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
        ])
    }

    func addAndPinSubview(_ view: UIView, insets: NSDirectionalEdgeInsets = .zero) {
        view.translatesAutoresizingMaskIntoConstraints = false
        addSubview(view)
        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: topAnchor, constant: insets.top),
            view.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -insets.bottom),
            view.leadingAnchor.constraint(equalTo: leadingAnchor, constant: insets.leading),
            view.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -insets.trailing),
        ])
    }

    func addAndPinSubviewToSafeArea(_ view: UIView, insets: NSDirectionalEdgeInsets = .zero) {
        view.translatesAutoresizingMaskIntoConstraints = false
        addSubview(view)
        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: insets.top),
            view.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -insets.bottom),
            view.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: insets.leading),
            view.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -insets.trailing),
        ])
    }

    /// Animates changes to one or more views alongside the keyboard.
    ///
    /// - Parameters:
    ///   - notification: Keyboard change notification.
    ///   - animations: A block containing the changes to commit to the views.
    static func animateAlongsideKeyboard(
        _ notification: Notification,
        animations: @escaping () -> Void
    ) {

        guard let userInfo = notification.userInfo,
              let animationCurveValue = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? Int,
              let animationDuration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double,
              let animationCurve = UIView.AnimationCurve(rawValue: animationCurveValue),
              animationDuration > 0 else {
            // Just run the animation block as a fallback
            animations()
            return
        }

        // Animate the container above the keyboard
        // Note: We prefer UIViewPropertyAnimator over UIView.animate because it handles consecutive animation calls better. Sometimes this happens when one text field resigns and another immediately becomes first responder.
        let animator = UIViewPropertyAnimator(duration: animationDuration, curve: animationCurve) {
            animations()
        }
        animator.startAnimation()
    }

    // Don't set isHidden redundantly or you might hit a bug: http://www.openradar.me/25087688
    func setHiddenIfNecessary(_ shouldHide: Bool) {
        if isHidden != shouldHide {
            isHidden = shouldHide
        }
    }

    func firstResponder() -> UIView? {
        for subview in subviews {
            if let firstResponder = subview.firstResponder() {
                return firstResponder
            }
        }
        return isFirstResponder ? self : nil
    }

    func updateTrailingAnchor(constant: CGFloat) {
        if let superview = superview {
            for constraint in superview.constraints where constraint.firstItem === self || constraint.secondItem === self {
                if constraint.firstAttribute == .trailing || constraint.secondAttribute == .trailing {
                    constraint.constant = constant
                    break
                }
            }
        }
    }

    static func makeSpacerView(width: CGFloat? = nil, height: CGFloat? = nil) -> UIView {
        let spacerView = UIView(frame: .zero)
        spacerView.translatesAutoresizingMaskIntoConstraints = false
        if let width {
            spacerView.widthAnchor.constraint(equalToConstant: width).isActive = true
        }
        if let height {
            spacerView.heightAnchor.constraint(equalToConstant: height).isActive = true
        }
        return spacerView
    }
}
