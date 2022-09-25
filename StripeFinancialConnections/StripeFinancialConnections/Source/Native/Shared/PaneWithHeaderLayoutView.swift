//
//  PaneWithHeaderLayoutView.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 9/12/22.
//

import Foundation
import UIKit
@_spi(STP) import StripeUICore

/// Reusable view that separates panes into three parts:
/// 1. A header that is part of a "content scroll view."
/// 2. A body that is part of a "content scroll view."
/// 3. A footer that is "locked" and does not get affected by scroll view
///
/// Purposefully NOT a `UIView` subclass because it should only be used via
/// `addToView` helper function.
final class PaneWithHeaderLayoutView {
    
    enum Icon {
        case view(UIView)
    }
    
    private let paneLayoutView: PaneLayoutView
    var scrollView: UIScrollView {
        return paneLayoutView.scrollView
    }
    
    init(
        icon: Icon? = nil,
        title: String,
        subtitle: String? = nil,
        contentView: UIView,
        footerView: UIView?
    ) {
        self.paneLayoutView = PaneLayoutView(
            contentView: {
                let verticalStackView = UIStackView(
                    arrangedSubviews: [
                        CreateHeaderView(icon: icon, title: title, subtitle: subtitle),
                        contentView,
                    ]
                )
                verticalStackView.axis = .vertical
                verticalStackView.spacing = 24
                verticalStackView.isLayoutMarginsRelativeArrangement = true
                verticalStackView.directionalLayoutMargins = NSDirectionalEdgeInsets(
                    top: icon != nil ? 8 : 16,
                    leading: 24,
                    bottom: 16,
                    trailing: 24
                )
                return verticalStackView
            }(),
            footerView: {
                if let footerView = footerView {
                    // This is only a `UIStackView` to add margins
                    let verticalStackView = UIStackView(
                        arrangedSubviews: [
                            footerView,
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

private func CreateHeaderView(
    icon: PaneWithHeaderLayoutView.Icon?,
    title: String,
    subtitle: String?
) -> UIView {
    let headerStackView = UIStackView()
    headerStackView.axis = .vertical
    headerStackView.spacing = 16
    headerStackView.alignment = .leading
    if let icon = icon {
        headerStackView.addArrangedSubview(
            CreateIconView(iconType: icon)
        )
    }
    headerStackView.addArrangedSubview(
        CreateTitleAndSubtitleView(
            title: title,
            subtitle: subtitle
        )
    )
    return headerStackView
}

private func CreateIconView(iconType: PaneWithHeaderLayoutView.Icon) -> UIView {
    switch iconType {
    case .view(let view):
        return view
    }
}

private func CreateTitleAndSubtitleView(title: String, subtitle: String?) -> UIView {
    let labelStackView = UIStackView()
    labelStackView.axis = .vertical
    labelStackView.spacing = 8
    
    let titleLabel = UILabel()
    titleLabel.font = .stripeFont(forTextStyle: .subtitle)
    titleLabel.textColor = .textPrimary
    titleLabel.numberOfLines = 0
    titleLabel.text = title
    labelStackView.addArrangedSubview(titleLabel)
    
    if let subtitle = subtitle {
        let subtitleLabel = UILabel()
        subtitleLabel.font = .stripeFont(forTextStyle: .body)
        subtitleLabel.textColor = .textSecondary
        subtitleLabel.numberOfLines = 0
        subtitleLabel.text = subtitle
        labelStackView.addArrangedSubview(subtitleLabel)
    }
    
    return labelStackView
}
