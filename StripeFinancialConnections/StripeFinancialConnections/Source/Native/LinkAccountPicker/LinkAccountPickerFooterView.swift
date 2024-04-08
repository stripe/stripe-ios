//
//  LinkAccountPickerFooterView.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 2/13/23.
//

import Foundation
@_spi(STP) import StripeUICore
import UIKit

final class LinkAccountPickerFooterView: UIView {

    private let defaultCta: String
    private let singleAccount: Bool
    private let didSelectConnectAccount: () -> Void

    private lazy var connectAccountButton: Button = {
        let connectAccountButton = Button.primary()
        connectAccountButton.title = defaultCta
        connectAccountButton.isEnabled = false // disable by default
        connectAccountButton.addTarget(self, action: #selector(didSelectLinkAccountsButton), for: .touchUpInside)
        connectAccountButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            connectAccountButton.heightAnchor.constraint(equalToConstant: 56)
        ])
        connectAccountButton.accessibilityIdentifier = "connect_accounts_button"
        return connectAccountButton
    }()

    init(
        defaultCta: String,
        isStripeDirect: Bool,
        businessName: String?,
        permissions: [StripeAPI.FinancialConnectionsAccount.Permissions],
        singleAccount: Bool,
        didSelectConnectAccount: @escaping () -> Void,
        didSelectMerchantDataAccessLearnMore: @escaping (URL) -> Void
    ) {
        self.defaultCta = defaultCta
        self.singleAccount = singleAccount
        self.didSelectConnectAccount = didSelectConnectAccount
        super.init(frame: .zero)

        let verticalStackView = HitTestStackView(
            arrangedSubviews: [
                MerchantDataAccessView(
                    isStripeDirect: isStripeDirect,
                    businessName: businessName,
                    permissions: permissions,
                    isNetworking: true,
                    font: .label(.small),
                    boldFont: .label(.smallEmphasized),
                    alignCenter: true,
                    didSelectLearnMore: didSelectMerchantDataAccessLearnMore
                ),
                connectAccountButton,
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
        addAndPinSubview(verticalStackView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func didSelectLinkAccountsButton() {
        didSelectConnectAccount()
    }

    func didSelectAccounts(_ selectedAccounts: [FinancialConnectionsAccountTuple]) {
        if
            singleAccount,
            let selectionCta = selectedAccounts.first?.accountPickerAccount.selectionCta
        {
            connectAccountButton.title = selectionCta
        } else {
            connectAccountButton.title = defaultCta
        }
        connectAccountButton.isEnabled = !selectedAccounts.isEmpty
    }

    func showLoadingView(_ show: Bool) {
        connectAccountButton.isLoading = show
    }
}
