//
//  UIKit+PaymentSheet.swift
//  StripeiOS
//
//  Created by Yuki Tokuhiro on 11/10/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import Foundation
import UIKit
import PassKit

enum PaymentSheetUI {
    static let defaultPadding: CGFloat = 20
    static let defaultSheetMargins: NSDirectionalEdgeInsets = NSDirectionalEdgeInsets(top: 0, leading: defaultPadding, bottom: 36, trailing: defaultPadding)
    static let defaultButtonCornerRadius: CGFloat = 6
    static let minimumTapSize: CGSize = CGSize(width: 44, height: 44)
    static let defaultAnimationDuration: TimeInterval = 0.2
    static let quickAnimationDuration: TimeInterval = 0.1
    /// The minimnum amount of time to spend processing before transitioning to success/failure
    static let minimumFlightTime: TimeInterval = 1
    static let delayBetweenSuccessAndDismissal: TimeInterval = 1.5

    static func makeErrorLabel() -> UILabel {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .footnote)
        label.textColor = .systemRed
        label.numberOfLines = 0
        return label
    }

    static func makeHeaderLabel() -> UILabel {
        let header = UILabel()
        header.text = STPLocalizedString("Add a payment method", "TODO")
        header.textColor = CompatibleColor.label
        header.font = .preferredFont(forTextStyle: .title3, weight: .bold)
        header.accessibilityTraits = [.header]
        return header
    }
}

extension PKPaymentButtonStyle {
    static var compatibleAutomatic: PKPaymentButtonStyle {
        if #available(iOS 14.0, *) {
            return .automatic
        } else {
            return .black
        }
    }
}

extension UIViewController {
    func switchContentIfNecessary(to toVC: UIViewController, containerView: UIView) {
        assert(children.count <= 1)
        // Swap out child view controllers if necessary
        if let fromVC = children.first {
            if fromVC == toVC {
                return
            }

            // Note: this transition doesn't animate if containerView is a UIStackView
            UIView.transition(
                with: containerView,
                duration: 0.2,
                options: [.transitionCrossDissolve, .allowAnimatedContent],
                animations: {
                    // Remove the old one
                    self.remove(childViewController: fromVC)

                    // Add the new one
                    self.addChild(toVC)
                    containerView.addAndPinSubview(toVC.view)
                    toVC.didMove(toParent: self)
                },
                completion: {_ in
                    UIAccessibility.post(notification: .screenChanged, argument: toVC.view)
                })
        } else {
            addChild(toVC)
            containerView.addAndPinSubview(toVC.view)
            toVC.didMove(toParent: self)
            containerView.setNeedsLayout()
            containerView.layoutIfNeeded()
            UIAccessibility.post(notification: .screenChanged, argument: toVC.view)
        }
    }

    func remove(childViewController: UIViewController) {
        childViewController.willMove(toParent: nil)
        childViewController.view.removeFromSuperview()
        childViewController.removeFromParent()
        childViewController.didMove(toParent: nil)
    }
}

extension UIView {
    // Don't set isHidden redundantly or you might hit a bug: http://www.openradar.me/25087688
    func setHiddenIfNecessary(_ shouldHide: Bool) {
        if isHidden != shouldHide {
            isHidden = shouldHide
        }
    }

    func addAndPinSubview(_ view: UIView) {
        view.translatesAutoresizingMaskIntoConstraints = false
        addSubview(view)
        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
            view.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor),
            view.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),

        ])
    }
}
