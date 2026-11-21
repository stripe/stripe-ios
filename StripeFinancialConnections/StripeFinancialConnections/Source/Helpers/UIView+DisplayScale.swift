//
//  UIView+DisplayScale.swift
//  StripeFinancialConnections
//

import UIKit

extension UITraitEnvironment where Self: UIView {

    /// Calls `update` with the view's display scale now, and again whenever it changes, such as when
    /// the window moves to a display with a different scale. Use this for values measured in pixels.
    ///
    /// Before iOS 17, `update` only runs once.
    func stp_updateForDisplayScale(_ update: @escaping (Self, CGFloat) -> Void) {
        update(self, traitCollection.displayScale)
        if #available(iOS 17.0, *) {
            registerForTraitChanges([UITraitDisplayScale.self]) { (view: Self, _: UITraitCollection) in
                update(view, view.traitCollection.displayScale)
            }
        }
    }
}

extension UIView {

    /// A height constraint of `pixels` pixels at the view's display scale, which follows changes to it.
    func stp_heightConstraint(pixels: CGFloat) -> NSLayoutConstraint {
        let heightConstraint = heightAnchor.constraint(equalToConstant: 0)
        stp_updateForDisplayScale { _, displayScale in
            heightConstraint.constant = pixels / displayScale
        }
        return heightConstraint
    }
}
