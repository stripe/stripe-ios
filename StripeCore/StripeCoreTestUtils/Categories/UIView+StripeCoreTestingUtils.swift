//
//  UIView+StripeCoreTestingUtils.swift
//  StripeCoreTestUtils
//
//  Created by Mel Ludowise on 10/4/21.
//

import UIKit

extension UIView {
    /// Forces this view hierarchy into a right-to-left layout without changing the app's language or global appearance state.
    /// Descendants inherit this direction unless they explicitly preserve left-to-right semantics for directional data.
    public func forceRightToLeftLayout(guardExisting: Bool = false) {
        // Preserve explicit semantics such as OneTimeCodeTextField's left-to-right digit order.
        if guardExisting && semanticContentAttribute != .unspecified { return }
        semanticContentAttribute = .forceRightToLeft
        setNeedsLayout()
        subviews.forEach { $0.forceRightToLeftLayout(guardExisting: true) }
    }

    /// Constrains the view to the given width and autosizes its height.
    ///
    /// - Parameter width: Resizes the view to this width
    public func autosizeHeight(width: CGFloat) {
        translatesAutoresizingMaskIntoConstraints = false
        widthAnchor.constraint(equalToConstant: width).isActive = true
        setNeedsLayout()
        layoutIfNeeded()
        frame = .init(
            origin: .zero,
            size: systemLayoutSizeFitting(CGSize(width: width, height: UIView.noIntrinsicMetric))
        )
    }
}
