//
//  InstitutionCellView.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 11/28/23.
//

import Foundation
@_spi(STP) import StripeUICore
import UIKit

final class InstitutionCellView: UIView {
    private let appearance: FinancialConnectionsAppearance

    private lazy var horizontalStackView: UIStackView = {
        let horizontalStackView = UIStackView()
        horizontalStackView.axis = .horizontal
        horizontalStackView.spacing = 12
        horizontalStackView.alignment = .center
        horizontalStackView.isLayoutMarginsRelativeArrangement = true
        horizontalStackView.directionalLayoutMargins = NSDirectionalEdgeInsets(
            top: 8,
            leading: 24,
            bottom: 8,
            trailing: 24
        )
        return horizontalStackView
    }()
    private lazy var labelStackView: UIStackView = {
        let labelStackView = UIStackView(
            arrangedSubviews: [
                titleLabel,
            ]
        )
        labelStackView.axis = .vertical
        labelStackView.spacing = 0
        return labelStackView
    }()
    private lazy var titleLabel: AttributedLabel = {
        let titleLabel = AttributedLabel(
            font: .label(.largeEmphasized),
            textColor: FinancialConnectionsAppearance.Colors.textDefault
        )
        return titleLabel
    }()
    private lazy var subtitleLabel: AttributedLabel = {
        let subtitleLabel = AttributedLabel(
            font: .label(.medium),
            textColor: FinancialConnectionsAppearance.Colors.textSubdued
        )
        return subtitleLabel
    }()
    private var iconView: UIView?
    private lazy var loadingView: ActivityIndicator = {
        let activityIndicator = ActivityIndicator(size: .medium)
        activityIndicator.color = appearance.colors.spinner
        activityIndicator.startAnimating()

        // re-size `ActivityIndicator` to a size we desire
        // because its hard-coded
        let mediumIconDiameter: CGFloat = 20
        let desiredIconDiameter: CGFloat = 24
        let transform = CGAffineTransform(
            scaleX: desiredIconDiameter / mediumIconDiameter,
            y: desiredIconDiameter / mediumIconDiameter
        )
        activityIndicator.transform = transform
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            activityIndicator.widthAnchor.constraint(equalToConstant: desiredIconDiameter),
            activityIndicator.heightAnchor.constraint(equalToConstant: desiredIconDiameter),
        ])
        return activityIndicator
    }()

    init(appearance: FinancialConnectionsAppearance) {
        self.appearance = appearance
        super.init(frame: .zero)
        backgroundColor = .clear
        addAndPinSubview(horizontalStackView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func customize(iconView: UIView?, title: String, subtitle: String?) {
        // clear previous state
        self.iconView?.removeFromSuperview()
        self.iconView = nil
        labelStackView.removeFromSuperview()
        subtitleLabel.removeFromSuperview()

        // setup labels
        titleLabel.setText(title)
        if let subtitle = subtitle {
            subtitleLabel.setText(subtitle)
            labelStackView.addArrangedSubview(subtitleLabel)
        }

        // setup the main view
        if let iconView = iconView {
            horizontalStackView.addArrangedSubview(iconView)
            self.iconView = iconView
        }
        horizontalStackView.addArrangedSubview(labelStackView)
    }

    func showLoadingView(_ show: Bool) {
        loadingView.removeFromSuperview()

        if show {
            horizontalStackView.addArrangedSubview(loadingView)
            loadingView.startAnimating()
        } else {
            loadingView.stopAnimating()
        }
    }
}
