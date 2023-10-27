//
//  SuccessAccountListView.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 8/16/22.
//

import Foundation
@_spi(STP) import StripeUICore
import UIKit

final class SuccessAccountListView: UIView {

    private let maxNumberOfAccountsListedBeforeShowingOnlyAccountCount = 4

    init(institution: FinancialConnectionsInstitution, linkedAccounts: [FinancialConnectionsPartnerAccount]) {
        super.init(frame: .zero)
        let accountListView: UIView
        if linkedAccounts.count > maxNumberOfAccountsListedBeforeShowingOnlyAccountCount {
            accountListView = CreateAccountCountView(institution: institution, numberOfAccounts: linkedAccounts.count)
        } else {
            accountListView = CreateAccountListView(institution: institution, accounts: linkedAccounts)
        }
        addAndPinSubview(accountListView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private func CreateAccountCountView(institution: FinancialConnectionsInstitution, numberOfAccounts: Int) -> UIView {
    let numberOfAccountsLabel = AttributedLabel(
        font: .label(.mediumEmphasized),
        textColor: .textSecondary
    )
    numberOfAccountsLabel.textAlignment = .right
    numberOfAccountsLabel.text = String(
        format: STPLocalizedString(
            "%d accounts",
            "An textual description of how many bank accounts user has successfully connected (or linked). Once the bank accounts are connected (or linked), the user will be able to use those bank accounts for payments. %d will be replaced by the number of accounts connected (or linked)."
        ),
        numberOfAccounts
    )

    let horizontalStackView = UIStackView(
        arrangedSubviews: [
            CreateIconWithLabelView(institution: institution, text: institution.name),
            numberOfAccountsLabel,
        ]
    )
    horizontalStackView.axis = .horizontal
    horizontalStackView.distribution = .fillProportionally
    horizontalStackView.spacing = 8
    return horizontalStackView
}

private func CreateAccountListView(
    institution: FinancialConnectionsInstitution,
    accounts: [FinancialConnectionsPartnerAccount]
) -> UIView {
    let accountRowVerticalStackView = UIStackView(
        arrangedSubviews: accounts.map { account in
            CreateAccountRowView(institution: institution, account: account)
        }
    )
    accountRowVerticalStackView.axis = .vertical
    accountRowVerticalStackView.spacing = 16
    return accountRowVerticalStackView
}

private func CreateAccountRowView(
    institution: FinancialConnectionsInstitution,
    account: FinancialConnectionsPartnerAccount
) -> UIView {
    let horizontalStackView = UIStackView()
    horizontalStackView.axis = .horizontal
    horizontalStackView.spacing = 8

    horizontalStackView.addArrangedSubview(
        CreateIconWithLabelView(
            institution: institution,
            text: account.name
        )
    )

    if let displayableAccountNumbers = account.displayableAccountNumbers {
        let displayableAccountNumberLabel = AttributedLabel(
            font: .label(.mediumEmphasized),
            textColor: .textSecondary
        )
        displayableAccountNumberLabel.text = "••••\(displayableAccountNumbers)"
        // compress `account.name` instead of account number if text is long
        displayableAccountNumberLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        horizontalStackView.addArrangedSubview(displayableAccountNumberLabel)
    }

    return horizontalStackView
}

private func CreateIconWithLabelView(institution: FinancialConnectionsInstitution, text: String) -> UIView {
    let institutionIconView = InstitutionIconView(size: .small)
    institutionIconView.setImageUrl(institution.icon?.default)

    let label = AttributedLabel(
        font: .label(.mediumEmphasized),
        textColor: .textPrimary
    )
    label.text = text
    label.translatesAutoresizingMaskIntoConstraints = false
    label.setContentHuggingPriority(.defaultHigh, for: .horizontal)
    // compress `account.name` instead of account number if text is long
    label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

    let horizontalStackView = UIStackView(
        arrangedSubviews: [
            institutionIconView,
            label,
        ]
    )
    horizontalStackView.axis = .horizontal
    horizontalStackView.spacing = 8
    return horizontalStackView
}
