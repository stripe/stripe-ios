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

    private var constraint: NSLayoutConstraint?
    
    init(contentView: UIView, footerView: UIView?) {
        self.scrollViewContentView = contentView

        let scrollView = UIScrollView()
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
        
        
        paneLayoutView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(paneLayoutView)
        NSLayoutConstraint.activate([
            paneLayoutView.topAnchor.constraint(greaterThanOrEqualTo: view.safeAreaLayoutGuide.topAnchor, constant: 0),
            paneLayoutView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: 0),
            paneLayoutView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 0),
            paneLayoutView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: 0),
        ])
        
        // this function encapsulates an error-prone sequence where we
        // must add `paneLayoutView` (and all it's subviews) to the `view`
        // BEFORE we can add a constraint for `UIScrollView` content
//        view.addAndPinSubviewToSafeArea(paneLayoutView)
        scrollViewContentView?.widthAnchor.constraint(equalTo: view.safeAreaLayoutGuide.widthAnchor).isActive = true
        
        let scrollViewHeightConstraint = scrollView.heightAnchor.constraint(
            equalTo: scrollView.contentLayoutGuide.heightAnchor)
        scrollViewHeightConstraint.priority = .fittingSizeLevel
        scrollViewHeightConstraint.isActive = true
        self.constraint = scrollViewHeightConstraint
    }
}
