//
//  UIView+StripeUICore.swift
//  StripeUICore
//
//  Created by Mel Ludowise on 9/16/21.
//

import Foundation
import UIKit

@_spi(STP) public extension UIView {
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

        guard let duration = userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber else {
            animations()
            return
        }

        // TODO(ramont): extract animation curve from `keyboardAnimationCurveUserInfoKey`
        // (see: http://www.openradar.me/42609976)

        UIView.animate(
            withDuration: duration.doubleValue,
            delay: 0,
            options: [.curveEaseOut],
            animations: animations
        )
    }
}
