//
//  SuccessHeaderView.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 8/15/22.
//

import Foundation
import UIKit
@_spi(STP) import StripeUICore

final class SuccessHeaderView: UIView {
    
    init(businessName: String?, isLinkingOneAccount: Bool) {
        super.init(frame: .zero)
        let verticalStackView = UIStackView(
            arrangedSubviews: [
                CreateSuccessIconView(),
                CreateTitleAndSubtitleView(
                    title: "Success!",
                    subtitle: CreateSubtitleText()
                ),
            ]
        )
        verticalStackView.axis = .vertical
        verticalStackView.spacing = 16
        verticalStackView.alignment = .leading
        addAndPinSubviewToSafeArea(verticalStackView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private func CreateSubtitleText() -> String {
    return "Your account was successfully linked to [Merchant] through Stripe."
}

private func CreateSuccessIconView() -> UIView {
    let successIconView = UIView()
    successIconView.backgroundColor = UIColor(
        red: 30.0 / 255.0,
        green: 166.0 / 255.0,
        blue: 114.0 / 255.0,
        alpha: 1.0
    )
    successIconView.layer.cornerRadius = 20 // TODO(kgaidis): add support for success icon
    
    successIconView.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
        successIconView.widthAnchor.constraint(equalToConstant: 40),
        successIconView.heightAnchor.constraint(equalToConstant: 40),
    ])
    return successIconView
}

private func CreateTitleAndSubtitleView(title: String, subtitle: String) -> UIView {
    let titleLabel = UILabel()
    titleLabel.font = .stripeFont(forTextStyle: .subtitle)
    titleLabel.textColor = .textPrimary
    titleLabel.numberOfLines = 0
    titleLabel.text = title
    let subtitleLabel = UILabel()
    subtitleLabel.font = .stripeFont(forTextStyle: .body)
    subtitleLabel.textColor = .textSecondary
    subtitleLabel.numberOfLines = 0
    subtitleLabel.text = subtitle
    let labelStackView = UIStackView(arrangedSubviews: [
        titleLabel,
        subtitleLabel,
    ])
    labelStackView.axis = .vertical
    labelStackView.spacing = 8
    return labelStackView
}

