//
//  AccountPickerFooterView.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 8/10/22.
//

import Foundation
@_spi(STP) import StripeUICore
import UIKit

final class AccountPickerFooterView: UIView {

    private let singleAccount: Bool
    private let didSelectLinkAccounts: () -> Void

    private lazy var linkAccountsButton: Button = {
        let linkAccountsButton = Button.primary()
        linkAccountsButton.addTarget(self, action: #selector(didSelectLinkAccountsButton), for: .touchUpInside)
        linkAccountsButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            linkAccountsButton.heightAnchor.constraint(equalToConstant: 56)
        ])
        linkAccountsButton.accessibilityIdentifier = "connect_accounts_button"
        return linkAccountsButton
    }()

    init(
        isStripeDirect: Bool,
        businessName: String?,
        permissions: [StripeAPI.FinancialConnectionsAccount.Permissions],
        singleAccount: Bool,
        didSelectLinkAccounts: @escaping () -> Void,
        didSelectMerchantDataAccessLearnMore: @escaping (URL) -> Void
    ) {
        self.singleAccount = singleAccount
        self.didSelectLinkAccounts = didSelectLinkAccounts
        super.init(frame: .zero)

        let verticalStackView = HitTestStackView(
            arrangedSubviews: [
                MerchantDataAccessView(
                    isStripeDirect: isStripeDirect,
                    businessName: businessName,
                    permissions: permissions,
                    isNetworking: false,
                    font: .label(.small),
                    boldFont: .label(.smallEmphasized),
                    alignCenter: true,
                    didSelectLearnMore: didSelectMerchantDataAccessLearnMore
                ),
                linkAccountsButton,
            ]
        )
        verticalStackView.axis = .vertical
        verticalStackView.spacing = 16
        verticalStackView.isLayoutMarginsRelativeArrangement = true
        verticalStackView.directionalLayoutMargins = NSDirectionalEdgeInsets(
            top: 16,
            leading: 24,
            bottom: 16,
            trailing: 24
        )
        addSubview(verticalStackView)
        addAndPinSubviewToSafeArea(verticalStackView)

        didSelectAccounts(count: 0)  // set the button title
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func didSelectLinkAccountsButton() {
        didSelectLinkAccounts()
    }

    func didSelectAccounts(count numberOfAccountsSelected: Int) {
        linkAccountsButton.isEnabled = (numberOfAccountsSelected > 0)

        let singleAccountButtonTitle = STPLocalizedString(
            "Connect account",
            "A button that allows users to confirm the process of saving their bank account for future payments. This button appears in a screen that allows users to select which bank accounts they want to use to pay for something."
        )
        let multipleAccountButtonTitle = STPLocalizedString(
            "Connect accounts",
            "A button that allows users to confirm the process of saving their bank accounts for future payments. This button appears in a screen that allows users to select which bank accounts they want to use to pay for something."
        )

        if numberOfAccountsSelected == 0 {
            if singleAccount {
                linkAccountsButton.title = singleAccountButtonTitle
            } else {
                linkAccountsButton.title = multipleAccountButtonTitle
            }
        } else if numberOfAccountsSelected == 1 {
            linkAccountsButton.title = singleAccountButtonTitle
        } else {  // numberOfAccountsSelected > 1
            linkAccountsButton.title = multipleAccountButtonTitle
        }
    }

    func startLoading() {
        linkAccountsButton.isLoading = true
    }
}
