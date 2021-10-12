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

        // Wrap in a view to size properly
        let container = UIView()
        container.addSubview(self)

        // Pin view to top of container
        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: topAnchor),
            container.trailingAnchor.constraint(equalTo: trailingAnchor),
            container.leadingAnchor.constraint(equalTo: leadingAnchor),
            container.bottomAnchor.constraint(greaterThanOrEqualTo: bottomAnchor),
        ])
        setContentHuggingPriority(.required, for: .vertical)
        setContentCompressionResistancePriority(.required, for: .vertical)

        container.frame.size = CGSize(width: width, height: CGFloat.greatestFiniteMagnitude)
        container.setNeedsLayout()
        container.layoutIfNeeded()

        removeFromSuperview()
    }
}
