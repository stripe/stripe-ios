//
//  InstitutionSearchTableViewCell.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 7/21/22.
//

import Foundation
@_spi(STP) import StripeUICore
import UIKit

final class InstitutionSearchTableViewCell: UITableViewCell {

    private lazy var institutionIconView: InstitutionIconView = {
        return InstitutionIconView(size: .medium)
    }()
    private lazy var titleLabel: AttributedLabel = {
        let titleLabel = AttributedLabel(
            font: .label(.largeEmphasized),
            textColor: .textPrimary
        )
        return titleLabel
    }()
    private lazy var subtitleLabel: AttributedLabel = {
        let subtitleLabel = AttributedLabel(
            font: .label(.small),
            textColor: .textSecondary
        )
        return subtitleLabel
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.backgroundColor = .customBackgroundColor

        let labelStackView = UIStackView(
            arrangedSubviews: [
                titleLabel,
                subtitleLabel,
            ]
        )
        labelStackView.axis = .vertical
        labelStackView.spacing = 0

        let cellStackView = UIStackView(
            arrangedSubviews: [
                institutionIconView,
                labelStackView,
            ]
        )
        cellStackView.axis = .horizontal
        cellStackView.spacing = 12
        cellStackView.alignment = .center
        cellStackView.isLayoutMarginsRelativeArrangement = true
        cellStackView.directionalLayoutMargins = NSDirectionalEdgeInsets(
            top: 10,
            leading: 24,
            bottom: 10,
            trailing: 24
        )
        contentView.addAndPinSubview(cellStackView)

        self.selectedBackgroundView = CreateSelectedBackgroundView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private func CreateSelectedBackgroundView() -> UIView {
    let selectedBackgroundView = UIView()
    selectedBackgroundView.backgroundColor = .backgroundContainer

    let topSeparatorView = UIView()
    topSeparatorView.backgroundColor = .borderNeutral
    let bottomSeparatorView = UIView()
    bottomSeparatorView.backgroundColor = .borderNeutral
    selectedBackgroundView.addSubview(topSeparatorView)
    selectedBackgroundView.addSubview(bottomSeparatorView)

    topSeparatorView.translatesAutoresizingMaskIntoConstraints = false
    bottomSeparatorView.translatesAutoresizingMaskIntoConstraints = false

    NSLayoutConstraint.activate([
        topSeparatorView.topAnchor.constraint(equalTo: selectedBackgroundView.topAnchor),
        topSeparatorView.leadingAnchor.constraint(equalTo: selectedBackgroundView.leadingAnchor),
        topSeparatorView.trailingAnchor.constraint(equalTo: selectedBackgroundView.trailingAnchor),
        topSeparatorView.heightAnchor.constraint(equalToConstant: 1.0 / stp_screenNativeScale),

        bottomSeparatorView.bottomAnchor.constraint(equalTo: selectedBackgroundView.bottomAnchor),
        bottomSeparatorView.leadingAnchor.constraint(equalTo: selectedBackgroundView.leadingAnchor),
        bottomSeparatorView.trailingAnchor.constraint(equalTo: selectedBackgroundView.trailingAnchor),
        bottomSeparatorView.heightAnchor.constraint(equalToConstant: 1.0 / stp_screenNativeScale),
    ])

    return selectedBackgroundView
}

// MARK: - Customize

extension InstitutionSearchTableViewCell {

        func customize(with institution: FinancialConnectionsInstitution) {
        institutionIconView.setImageUrl(institution.icon?.default)
        titleLabel.setText(institution.name)
        subtitleLabel.setText(AuthFlowHelpers.formatUrlString(institution.url) ?? "")
    }
}
