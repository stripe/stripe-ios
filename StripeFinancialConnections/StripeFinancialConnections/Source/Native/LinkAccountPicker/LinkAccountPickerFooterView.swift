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
    private let appearance: FinancialConnectionsAppearance
    private let didSelectConnectAccount: () -> Void

    private lazy var connectAccountButton: Button = {
        let connectAccountButton = Button.primary(appearance: appearance)
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
        aboveCta: String?,
        singleAccount: Bool,
        appearance: FinancialConnectionsAppearance,
        didSelectConnectAccount: @escaping () -> Void,
        didSelectMerchantDataAccessLearnMore: @escaping (URL) -> Void
    ) {
        self.defaultCta = defaultCta
        self.singleAccount = singleAccount
        self.appearance = appearance
        self.didSelectConnectAccount = didSelectConnectAccount
        super.init(frame: .zero)

        let verticalStackView = HitTestStackView()
        if let aboveCta {
            let merchantDataAccessLabel = AttributedTextView(
                font: .label(.small),
                boldFont: .label(.smallEmphasized),
                linkFont: .label(.small),
                textColor: FinancialConnectionsAppearance.Colors.textDefault,
                alignment: .center
            )
            merchantDataAccessLabel.setText(
                aboveCta,
                action: didSelectMerchantDataAccessLearnMore
            )
            verticalStackView.addArrangedSubview(merchantDataAccessLabel)
        }
        verticalStackView.addArrangedSubview(connectAccountButton)
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
