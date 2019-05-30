//
//  UIView+Layout.swift
//  Standard Integration (Sources Only)
//
//  Created by Yuki Tokuhiro on 5/30/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

import UIKit

extension UIView {
    // MARK: - Autolayout Helpers
    /**
     Add constraints to superview that anchor this view's top, leading, trailing
     and bottom edges to the superview's.
     This is *not* margin or safe area aware.
     - warning: This will crash if this view does not have a superview.
     - returns: A tuple containing the top, leading, trailing, and bottom
     constraints
     */
    @discardableResult
    public func anchorToSuperviewAnchors(withInsets insets: UIEdgeInsets = UIEdgeInsets.zero) ->
        (top: NSLayoutConstraint, leading: NSLayoutConstraint, trailing: NSLayoutConstraint, bottom: NSLayoutConstraint) {
            guard let superview = superview else {
                fatalError("must have a superview to anchor to")
            }
            
            let top = topAnchor.constraint(equalTo: superview.topAnchor, constant: insets.top)
            let leading = leadingAnchor.constraint(equalTo: superview.leadingAnchor, constant: insets.left)
            let trailing = superview.trailingAnchor.constraint(equalTo: trailingAnchor, constant: insets.right)
            let bottom = superview.bottomAnchor.constraint(equalTo: bottomAnchor, constant: insets.bottom)
            
            NSLayoutConstraint.activate([top, leading, trailing, bottom])
            return (top, leading, trailing, bottom)
    }
}
