//
//  InstitutionSearchTableViewCell.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 7/21/22.
//

import Foundation
import UIKit

final class InstitutionSearchTableViewCell: UITableViewCell {

    private lazy var institutionIconView: InstitutionIconView = {
        return InstitutionIconView(size: .medium)
    }()
    private lazy var titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.font = .stripeFont(forTextStyle: .bodyEmphasized)
        titleLabel.textColor = .textPrimary
        return titleLabel
    }()
    private lazy var subtitleLabel: UILabel = {
        let subtitleLabel = UILabel()
        subtitleLabel.font = .stripeFont(forTextStyle: .captionTight)
        subtitleLabel.textColor = .textDisabled
        return subtitleLabel
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.backgroundColor = .customBackgroundColor
        contentView.addSubview(institutionIconView)

        let labelStackView = UIStackView(
            arrangedSubviews: [
                titleLabel,
                subtitleLabel,
            ]
        )
        labelStackView.axis = .vertical
        labelStackView.spacing = 2
        contentView.addSubview(labelStackView)

        let horizontalPadding: CGFloat = 24.0
        institutionIconView.translatesAutoresizingMaskIntoConstraints = false
        labelStackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            institutionIconView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: horizontalPadding),
            institutionIconView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),

            labelStackView.leftAnchor.constraint(equalTo: institutionIconView.rightAnchor, constant: 12),

            labelStackView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            labelStackView.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -horizontalPadding),
        ])

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
        topSeparatorView.heightAnchor.constraint(equalToConstant: 1.0 / UIScreen.main.nativeScale),

        bottomSeparatorView.bottomAnchor.constraint(equalTo: selectedBackgroundView.bottomAnchor),
        bottomSeparatorView.leadingAnchor.constraint(equalTo: selectedBackgroundView.leadingAnchor),
        bottomSeparatorView.trailingAnchor.constraint(equalTo: selectedBackgroundView.trailingAnchor),
        bottomSeparatorView.heightAnchor.constraint(equalToConstant: 1.0 / UIScreen.main.nativeScale),
    ])

    return selectedBackgroundView
}

// MARK: - Customize

extension InstitutionSearchTableViewCell {

    func customize(with institution: FinancialConnectionsInstitution) {
        institutionIconView.setImageUrl(institution.icon?.default)
        titleLabel.text = institution.name
        subtitleLabel.text = AuthFlowHelpers.formatUrlString(institution.url)
    }
}
