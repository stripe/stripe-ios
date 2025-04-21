//
//  AccountPickerRowLabelView.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 1/5/24.
//

import Foundation
@_spi(STP) import StripeUICore
import UIKit

final class AccountPickerRowLabelView: UIView {

    private lazy var verticalLabelStackView: UIStackView = {
        let labelStackView = UIStackView()
        labelStackView.axis = .vertical
        labelStackView.spacing = 0
        labelStackView.alignment = .leading
        return labelStackView
    }()
    private lazy var titleLabel: AttributedLabel = {
        return AttributedLabel(
            font: .label(.largeEmphasized),
            textColor: FinancialConnectionsAppearance.Colors.textDefault
        )
    }()
    private lazy var horizontalSubtitleStackView: UIStackView = {
        let horizontalSubtitleStackView = UIStackView()
        horizontalSubtitleStackView.axis = .horizontal
        horizontalSubtitleStackView.spacing = 8
        return horizontalSubtitleStackView
    }()
    private lazy var subtitleLabel: AttributedLabel = {
        return AttributedLabel(
            font: .label(.medium),
            textColor: FinancialConnectionsAppearance.Colors.textSubdued
        )
    }()
    private lazy var subtitleBalanceView: UIView = {
        let paddingView = UIStackView(arrangedSubviews: [subtitleBalanceLabel])
        paddingView.axis = .vertical
        paddingView.isLayoutMarginsRelativeArrangement = true
        paddingView.directionalLayoutMargins = NSDirectionalEdgeInsets(
            top: 2,
            leading: 6,
            bottom: 2,
            trailing: 6
        )
        paddingView.backgroundColor = FinancialConnectionsAppearance.Colors.backgroundSecondary
        paddingView.layer.cornerRadius = 4
        return paddingView
    }()
    private lazy var subtitleBalanceLabel: AttributedLabel = {
        let trailingTitleLabel = AttributedLabel(
            font: .label(.small),
            textColor: FinancialConnectionsAppearance.Colors.textSubdued
        )
        return trailingTitleLabel
    }()

    init() {
        super.init(frame: .zero)
        verticalLabelStackView.addArrangedSubview(titleLabel)
        addAndPinSubview(verticalLabelStackView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func set(
        title: String,
        subtitle: String?,
        underlineSubtitle: Bool = false,
        balanceString: String? = nil
    ) {
        titleLabel.text = title

        horizontalSubtitleStackView.removeFromSuperview()
        subtitleLabel.removeFromSuperview()
        subtitleBalanceView.removeFromSuperview()
        if let subtitle = subtitle {
            subtitleLabel.setText(
                subtitle,
                underline: underlineSubtitle
            )
            horizontalSubtitleStackView.addArrangedSubview(subtitleLabel)
        }

        if let balanceString = balanceString {
            subtitleBalanceLabel.text = balanceString
            horizontalSubtitleStackView.addArrangedSubview(subtitleBalanceView)
        }

        if (subtitle != nil) || (balanceString != nil) {
            verticalLabelStackView.addArrangedSubview(horizontalSubtitleStackView)
        }
    }
}
