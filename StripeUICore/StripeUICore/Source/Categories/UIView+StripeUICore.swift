//
//  UIView+StripeUICore.swift
//  StripeUICore
//
//  Created by Mel Ludowise on 9/16/21.
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
            view.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor)
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
        let userInfo = notification.userInfo

        guard let duration = userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else {
            animations()
            return
        }

        // Get keyboard animation info
        // TODO(ramont): extract animation curve from `keyboardAnimationCurveUserInfoKey`
        // (see: http://www.openradar.me/42609976)
        let curve = UIView.AnimationCurve.easeOut

        // Animate the container above the keyboard
        // Note: We prefer UIViewPropertyAnimator over UIView.animate because it handles consecutive animation calls better. Sometimes this happens when one text field resigns and another immediately becomes first responder.
        let animator = UIViewPropertyAnimator(duration: duration, curve: curve) {
            animations()
        }
        animator.startAnimation()
    }
}
