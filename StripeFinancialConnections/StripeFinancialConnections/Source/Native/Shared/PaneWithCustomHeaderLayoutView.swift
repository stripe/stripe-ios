//
//  PaneWithCustomHeaderLayoutView.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 10/19/22.
//

import Foundation
@_spi(STP) import StripeUICore
import UIKit

/// Reusable view that separates panes into three parts:
/// 1. A header that is part of a "content scroll view."
/// 2. A body that is part of a "content scroll view."
/// 3. A footer that is "locked" and does not get affected by scroll view
///
/// Purposefully NOT a `UIView` subclass because it should only be used via
/// `addToView` helper function.
final class PaneWithCustomHeaderLayoutView {

    private let paneLayoutView: PaneLayoutView
    var scrollView: UIScrollView {
        return paneLayoutView.scrollView
    }

    init(
        headerView: UIView,
        headerTopMargin: CGFloat = 8.0,
        contentView: UIView,
        headerAndContentSpacing: CGFloat = 24.0,
        footerView: UIView?
    ) {
        self.paneLayoutView = PaneLayoutView(
            contentView: {
                let verticalStackView = HitTestStackView(
                    arrangedSubviews: [
                        headerView,
                        contentView,
                    ]
                )
                verticalStackView.axis = .vertical
                verticalStackView.spacing = headerAndContentSpacing
                verticalStackView.isLayoutMarginsRelativeArrangement = true
                verticalStackView.directionalLayoutMargins = NSDirectionalEdgeInsets(
                    top: headerTopMargin,
                    leading: 24,
                    bottom: 16,
                    trailing: 24
                )
                return verticalStackView
            }(),
            footerView: {
                if let footerView = footerView {
                    // This is only a `HitTestStackView` to add margins
                    let verticalStackView = HitTestStackView(
                        arrangedSubviews: [
                            footerView
                        ]
                    )
                    verticalStackView.axis = .vertical
                    verticalStackView.spacing = 0
                    verticalStackView.isLayoutMarginsRelativeArrangement = true
                    verticalStackView.directionalLayoutMargins = NSDirectionalEdgeInsets(
                        top: 20,
                        leading: 24,
                        bottom: 24,
                        trailing: 24
                    )
                    return verticalStackView
                } else {
                    return nil
                }
            }()
        )
    }

    func addTo(view: UIView) {
        paneLayoutView.addTo(view: view)
    }
}
