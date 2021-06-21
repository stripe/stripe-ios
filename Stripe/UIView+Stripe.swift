//
//  UIView+Stripe.swift
//  StripeiOS
//
//  Created by Yuki Tokuhiro on 6/4/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation
import UIKit

extension UIView {
    // Don't set isHidden redundantly or you might hit a bug: http://www.openradar.me/25087688
    func setHiddenIfNecessary(_ shouldHide: Bool) {
        if isHidden != shouldHide {
            isHidden = shouldHide
        }
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

    func firstResponder() -> UIView? {
        for subview in subviews {
            if let firstResponder = subview.firstResponder() {
                return firstResponder
            }
        }
        return isFirstResponder ? self : nil
    }
}
