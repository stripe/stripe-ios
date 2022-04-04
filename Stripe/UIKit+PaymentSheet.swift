//
//  UIKit+PaymentSheet.swift
//  StripeiOS
//
//  Created by Yuki Tokuhiro on 11/10/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import Foundation
import PassKit
import UIKit
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore

enum PaymentSheetUI {
    /// The padding between views in the sheet e.g., between the bottom of the form and the Pay button
    static let defaultPadding: CGFloat = 20
    static let defaultMargins: NSDirectionalEdgeInsets = .insets(
        leading: defaultPadding, trailing: defaultPadding)
    static let defaultSheetMargins: NSDirectionalEdgeInsets = .insets(
        leading: defaultPadding, bottom: 36, trailing: defaultPadding)
    static let minimumTapSize: CGSize = CGSize(width: 44, height: 44)
    static let defaultAnimationDuration: TimeInterval = 0.2
    static let quickAnimationDuration: TimeInterval = 0.1
    /// The minimnum amount of time to spend processing before transitioning to success/failure
    static let minimumFlightTime: TimeInterval = 1
    static let delayBetweenSuccessAndDismissal: TimeInterval = 1.5
    static let minimumHitArea = CGSize(width: 44, height: 44)

    static func makeHeaderLabel(appearance: PaymentSheet.Appearance) -> UILabel {
        let header = UILabel()
        header.textColor = appearance.color.text
        header.numberOfLines = 2
        header.font = appearance.scaledFont(for: appearance.font.regular.bold, style: .title3, maximumPointSize: 35)
        header.accessibilityTraits = [.header]
        header.adjustsFontSizeToFitWidth = true
        header.adjustsFontForContentSizeCategory = true
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
    func switchContentIfNecessary(
        to toVC: UIViewController, containerView: DynamicHeightContainerView
    ) {
        assert(children.count <= 1)
        // Swap out child view controllers if necessary
        if let fromVC = children.first {
            guard fromVC != toVC else {
                return
            }

            // Add the new one
            self.addChild(toVC)
            toVC.view.alpha = 0
            containerView.addPinnedSubview(toVC.view)
            containerView.layoutIfNeeded()  // Lay the view out now or it animates layout from a zero size

            // Remove the child view controller, but don't remove its view yet - keep it on screen so we can fade it out
            fromVC.willMove(toParent: nil)
            fromVC.removeFromParent()
            
            animateHeightChange(
                {
                    containerView.updateHeight()
                    toVC.didMove(toParent: self)
                    fromVC.view.alpha = 0
                    toVC.view.alpha = 1
                },
                completion: { _ in
                    // Remove the old one
                    self.remove(childViewController: fromVC)
                    UIAccessibility.post(notification: .screenChanged, argument: toVC.view)
                }
            )
        } else {
            addChild(toVC)
            containerView.addPinnedSubview(toVC.view)
            containerView.updateHeight()
            toVC.didMove(toParent: self)
            containerView.setNeedsLayout()
            containerView.layoutIfNeeded()
            UIAccessibility.post(notification: .screenChanged, argument: toVC.view)
        }
    }

    func remove(childViewController: UIViewController) {
        childViewController.view.removeFromSuperview()
        childViewController.didMove(toParent: nil)
    }
}

extension UIFont {
    var bold: UIFont { return withWeight(.bold) }
    var medium: UIFont { return withWeight(.medium) }

    private func withWeight(_ weight: UIFont.Weight) -> UIFont {
        var attributes = fontDescriptor.fontAttributes
        var traits = (attributes[.traits] as? [UIFontDescriptor.TraitKey: Any]) ?? [:]

        traits[.weight] = weight

        attributes[.name] = nil // nil out name so we fallback on the font family to compute the correct weight
        attributes[.traits] = traits
        attributes[.family] = familyName

        let descriptor = UIFontDescriptor(fontAttributes: attributes)

        return UIFont(descriptor: descriptor, size: pointSize)
    }
}
