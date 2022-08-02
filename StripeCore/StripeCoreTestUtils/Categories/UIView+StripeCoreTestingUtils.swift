//
//  UIView+StripeCoreTestingUtils.swift
//  StripeCoreTestUtils
//
//  Created by Mel Ludowise on 10/4/21.
//

import UIKit

public extension UIView {
    /**
     Constrains the view to the given width and autosizes its height.

     - Parameters:
       - width: Resizes the view to this width
     */
    func autosizeHeight(width: CGFloat) {
        translatesAutoresizingMaskIntoConstraints = false
        widthAnchor.constraint(equalToConstant: width).isActive = true
        setNeedsLayout()
        layoutIfNeeded()
        frame = .init(origin: .zero, size: systemLayoutSizeFitting(CGSize(width: width, height: UIView.noIntrinsicMetric)))
    }
}
