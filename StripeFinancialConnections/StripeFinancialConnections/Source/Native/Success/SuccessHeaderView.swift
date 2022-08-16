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
                    subtitle: CreateSubtitleText(businessName: businessName, isLinkingOneAccount: isLinkingOneAccount)
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

private func CreateSubtitleText(businessName: String?, isLinkingOneAccount: Bool) -> String {
    if isLinkingOneAccount {
        if let businessName = businessName {
            return String(format: STPLocalizedString("Your account was successfully linked to %@ through Stripe.", "The subtitle/description of the success screen that appears when a user is done with the process of connecting their bank account to an application. Now that the bank account is connected (or linked), the user will be able to use the bank account for payments. %@ will be replaced by the business name, for example, The Coca-Cola Company."), businessName)
        } else {
            return STPLocalizedString("Your account was successfully linked to Stripe.", "The subtitle/description of the success screen that appears when a user is done with the process of connecting their bank account to an application. Now that the bank account is connected (or linked), the user will be able to use the bank account for payments.")
        }
    } else { // multiple bank accounts
        if let businessName = businessName {
            return String(format: STPLocalizedString("Your accounts were successfully linked to %@ through Stripe.", "The subtitle/description of the success screen that appears when a user is done with the process of connecting their bank accounts to an application. Now that the bank accounts are connected (or linked), the user will be able to use those bank accounts for payments. %@ will be replaced by the business name, for example, The Coca-Cola Company."), businessName)
        } else {
            return STPLocalizedString("Your accounts were successfully linked to Stripe.", "The subtitle/description of the success screen that appears when a user is done with the process of connecting their bank accounts to an application. Now that the bank accounts are connected (or linked), the user will be able to use those bank accounts for payments.")
        }
    }
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

