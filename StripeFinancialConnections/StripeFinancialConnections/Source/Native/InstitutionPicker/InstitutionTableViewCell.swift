//
//  InstitutionTableViewCell.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 11/28/23.
//

import Foundation
@_spi(STP) import StripeUICore
import UIKit

final class InstitutionTableViewCell: UITableViewCell {
    private lazy var institutionIconView: InstitutionIconView = {
        return InstitutionIconView()
    }()

    private var institutionCellView: InstitutionCellView?

    private lazy var overlayView: UIView = {
        let overlayView = UIView()
        overlayView.backgroundColor = FinancialConnectionsAppearance.Colors.background.withAlphaComponent(0.8)
        overlayView.alpha = 0
        return overlayView
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        adjustBackgroundColor(isHighlighted: false)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        adjustBackgroundColor(isHighlighted: highlighted)
    }

    private func adjustBackgroundColor(isHighlighted: Bool) {
        contentView.backgroundColor = isHighlighted ? FinancialConnectionsAppearance.Colors.backgroundHighlighted : FinancialConnectionsAppearance.Colors.background
        backgroundColor = contentView.backgroundColor

        // fix a bug where the background color of a
        // rotated, selected cell was wrong
        let selectedBackgroundView = UIView()
        selectedBackgroundView.backgroundColor = contentView.backgroundColor
        self.selectedBackgroundView = selectedBackgroundView
    }

    func showLoadingView(_ show: Bool) {
        institutionCellView?.showLoadingView(show)
    }

    func showOverlayView(_ show: Bool) {
        if overlayView.superview == nil {
            contentView.addAndPinSubview(overlayView)
        }
        UIView.animate(
            withDuration: 0.3,
            delay: 0,
            usingSpringWithDamping: 1,
            initialSpringVelocity: 0.3,
            animations: {
                self.overlayView.alpha = show ? 1.0 : 0
            }
        )
    }
}

// MARK: - Customize

extension InstitutionTableViewCell {

    func customize(with institution: FinancialConnectionsInstitution, appearance: FinancialConnectionsAppearance) {
        let institutionCellView = InstitutionCellView(appearance: appearance)
        institutionIconView.setImageUrl(institution.icon?.default)

        institutionCellView.customize(
            iconView: institutionIconView,
            title: institution.name,
            subtitle: AuthFlowHelpers.formatUrlString(institution.url)
        )

        // Ensure the cell view isn't added to superview more than once.
        self.institutionCellView?.removeFromSuperview()
        contentView.addAndPinSubview(institutionCellView)

        self.institutionCellView = institutionCellView
    }
}
