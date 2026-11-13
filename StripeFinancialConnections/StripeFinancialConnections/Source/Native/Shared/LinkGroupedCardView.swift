//
//  LinkGroupedCardView.swift
//  StripeFinancialConnections
//
//  Created by Mat Schmid on 2026-11-12.
//

import Foundation
@_spi(InternalOnlyAPI) import StripeUICore
import UIKit

/// A rounded card that groups a list of rows, used by the Link theme.
func CreateLinkGroupedCardView(
    contentView: UIView,
    appearance: FinancialConnectionsAppearance,
    cornerRadius: CGFloat = 12
) -> UIView {
    let cardView = UIView()
    cardView.backgroundColor = appearance.colors.surfaceSecondary
    cardView.layer.cornerRadius = cornerRadius
    cardView.layer.masksToBounds = true
    cardView.addAndPinSubview(contentView)
    return cardView
}

/// A divider placed between rows inside a `CreateLinkGroupedCardView` card.
///
/// - Parameter leadingInset: Aligns the divider with the start of the row content.
func CreateLinkGroupedCardSeparatorView(leadingInset: CGFloat = 0) -> UIView {
    let containerView = UIView()
    let separatorView = UIView()
    separatorView.backgroundColor = FinancialConnectionsAppearance.Colors.dividerOnCard
    separatorView.translatesAutoresizingMaskIntoConstraints = false
    containerView.addSubview(separatorView)
    NSLayoutConstraint.activate([
        separatorView.heightAnchor.constraint(equalToConstant: FinancialConnectionsAppearance.linkDividerThickness),
        separatorView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: leadingInset),
        separatorView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
        separatorView.topAnchor.constraint(equalTo: containerView.topAnchor),
        separatorView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
    ])
    return containerView
}
