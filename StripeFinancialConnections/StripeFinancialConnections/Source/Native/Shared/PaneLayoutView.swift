//
//  PaneLayoutView.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 9/12/22.
//

import Foundation
@_spi(STP) import StripeUICore
import UIKit

/// Reusable view that separates panes into two parts:
/// 1. A scroll view for content
/// 2. A footer that is "locked" and does not get affected by scroll view
///
/// Purposefully NOT a `UIView` subclass because it should only be used via
/// `addToView` helper function.
final class PaneLayoutView {

    private weak var scrollViewContentView: UIView?
    private let paneLayoutView: UIView
    let scrollView: UIScrollView

    init(contentView: UIView, footerView: UIView?) {
        self.scrollViewContentView = contentView

        let scrollView = AutomaticShadowScrollView()
        self.scrollView = scrollView
        scrollView.addAndPinSubview(contentView)

        let verticalStackView = HitTestStackView(
            arrangedSubviews: [
                scrollView
            ]
        )
        if let footerView = footerView {
            verticalStackView.addArrangedSubview(footerView)
        }
        verticalStackView.spacing = 0
        verticalStackView.axis = .vertical
        self.paneLayoutView = verticalStackView
    }

    func addTo(view: UIView) {
        // This function encapsulates an error-prone sequence where we
        // must add `paneLayoutView` (and all it's subviews) to the `view`
        // BEFORE we can add a constraint for `UIScrollView` content
        view.addAndPinSubviewToSafeArea(paneLayoutView)
        scrollViewContentView?.widthAnchor.constraint(equalTo: view.safeAreaLayoutGuide.widthAnchor).isActive = true

        // Fit the scroll view height to be the size of the
        // scroll view contents
        //
        // For exampple, this is needed for `SheetViewController`
        // to automatically re-size the sheet to the size of contents
        let scrollViewHeightConstraint = scrollView.heightAnchor.constraint(
            equalTo: scrollView.contentLayoutGuide.heightAnchor)
        scrollViewHeightConstraint.priority = .fittingSizeLevel
        scrollViewHeightConstraint.isActive = true
    }

    func createView() -> UIView {
        let containerView = UIView()
        addTo(view: containerView)
        return containerView
    }
}

// Automatically adds a shadow to the bottom
// if the content is scrollable
private class AutomaticShadowScrollView: UIScrollView {

    private var shadowView: UIView?

    override func layoutSubviews() {
        super.layoutSubviews()

        let canScroll = contentSize.height > bounds.height
        if canScroll && shadowView == nil {
            let shadowView = UIView()
            self.shadowView = shadowView
            shadowView.layer.shadowColor = UIColor.textDefault.cgColor
            shadowView.layer.shadowOpacity = 0.77
            shadowView.layer.shadowOffset = CGSize(width: 0, height: -4)
            shadowView.layer.shadowRadius = 10
            // if the background color is clear, iOS will
            // not draw a shadow
            shadowView.backgroundColor = UIColor.customBackgroundColor
            addSubview(shadowView)
        } else if !canScroll {
            shadowView?.removeFromSuperview()
            shadowView = nil
        }

        if let shadowView {
            // smaller shadow width "smoothens" the shadow 
            // around the leading/trailing edges
            let x = Constants.Layout.defaultHorizontalMargin / 2
            // move the `shadowView` to keep being at the bottom of visible bounds
            shadowView.frame = CGRect(
                x: x,
                y: contentOffset.y + bounds.height,
                width: bounds.width - (2 * x),
                height: 1
            )

            // slowly fade the `shadowView` as user scrolls to bottom
            //
            // the fade will only activate when we reach `startFadingDistanceToBottom`
            let distanceToBottom = contentSize.height - (contentOffset.y + bounds.size.height)
            let startFadingDistanceToBottom: CGFloat = 24
            let remainingFadeDistance = max(0, min(startFadingDistanceToBottom, distanceToBottom))
            shadowView.alpha = remainingFadeDistance / startFadingDistanceToBottom
        }
    }
}
