//
//  SuccessAccountListView.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 8/16/22.
//

import Foundation
import UIKit
@_spi(STP) import StripeUICore

@available(iOSApplicationExtension, unavailable)
final class SuccessAccountListView: UIView {
    
    init(institution: FinancialConnectionsInstitution, linkedAccounts: [FinancialConnectionsPartnerAccount]) {
        super.init(frame: .zero)
        let accountListView: UIView
        
        let accountCollapseThreshold = 4
        if linkedAccounts.count > accountCollapseThreshold {
            accountListView = CreateAccountNumberView(institution: institution, numberOfAccounts: linkedAccounts.count)
        } else {
            accountListView = CreateAccountListView(institution: institution, accounts: linkedAccounts)
        }
        
        addAndPinSubview(accountListView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private func CreateAccountNumberView(institution: FinancialConnectionsInstitution, numberOfAccounts: Int) -> UIView {
    let numberOfAccountsLabel = UILabel()
    numberOfAccountsLabel.textAlignment = .right
    numberOfAccountsLabel.font = .stripeFont(forTextStyle: .captionEmphasized)
    numberOfAccountsLabel.textColor = .textSecondary
    numberOfAccountsLabel.text = String(format: STPLocalizedString("%d accounts", "An textual description of how many bank accounts user has successfully connected (or linked). Once the bank accounts are connected (or linked), the user will be able to use those bank accounts for payments. %d will be replaced by the number of accounts connected (or linked)."), numberOfAccounts)
    
    let horizontalStackView = UIStackView(
        arrangedSubviews: [
            CreateIconWithLabelView(instituion: institution, text: institution.name),
            numberOfAccountsLabel,
        ]
    )
    horizontalStackView.axis = .horizontal
    horizontalStackView.distribution = .fillProportionally
    horizontalStackView.spacing = 8
    return horizontalStackView
}

private func CreateAccountListView(institution: FinancialConnectionsInstitution, accounts: [FinancialConnectionsPartnerAccount]) -> UIView {
    let accountRowVerticalStackView = UIStackView(
        arrangedSubviews: accounts.map { account in
            CreateAccountRowView(institution: institution, account: account)
        }
    )
    accountRowVerticalStackView.axis = .vertical
    accountRowVerticalStackView.spacing = 16
    return accountRowVerticalStackView
}

private func CreateAccountRowView(institution: FinancialConnectionsInstitution, account: FinancialConnectionsPartnerAccount) -> UIView {
    let horizontalStackView = UIStackView()
    horizontalStackView.axis = .horizontal
    horizontalStackView.spacing = 8

    horizontalStackView.addArrangedSubview(
        CreateIconWithLabelView(
            instituion: institution,
            text: account.name
        )
    )
    if let displayableAccountNumbers = account.displayableAccountNumbers {
        let displayableAccountNumberLabel = UILabel()
        displayableAccountNumberLabel.font = .stripeFont(forTextStyle: .captionEmphasized)
        displayableAccountNumberLabel.textColor = .textSecondary
        displayableAccountNumberLabel.text = "••••\(displayableAccountNumbers)"
        horizontalStackView.addArrangedSubview(displayableAccountNumberLabel)
    }
    
    return horizontalStackView
}

private func CreateIconWithLabelView(instituion: FinancialConnectionsInstitution, text: String) -> UIView {
    let institutionIconImageView = CreateInstitutionIconView()
    
    let institutionLabel = UILabel()
    institutionLabel.font = .stripeFont(forTextStyle: .captionEmphasized)
    institutionLabel.textColor = .textPrimary
    institutionLabel.text = text
    institutionLabel.translatesAutoresizingMaskIntoConstraints = false
    institutionLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
    
    let horizontalStackView = UIStackView(
        arrangedSubviews: [
            institutionIconImageView,
            institutionLabel,
        ]
    )
    horizontalStackView.axis = .horizontal
    horizontalStackView.spacing = 8
    return horizontalStackView
}

private func CreateInstitutionIconView() -> UIView {
    let institutionIconImageView = UIImageView()
    institutionIconImageView.backgroundColor = .textDisabled // TODO(kgaidis): add icon
    institutionIconImageView.layer.cornerRadius = 6
    institutionIconImageView.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
        institutionIconImageView.widthAnchor.constraint(equalToConstant: 24),
        institutionIconImageView.heightAnchor.constraint(equalToConstant: 24),
    ])
    return institutionIconImageView
}
