//
//  LinkAccountPickerFooterView.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 2/13/23.
//

import Foundation
@_spi(STP) import StripeUICore
import UIKit

@available(iOSApplicationExtension, unavailable)
final class LinkAccountPickerFooterView: UIView {

    private let singleAccount: Bool
    private let didSelectConnectAccount: () -> Void

    private lazy var connectAccountButton: Button = {
        let connectAccountButton = Button(configuration: .financialConnectionsPrimary)
        connectAccountButton.title = STPLocalizedString(
            "Connect account",
            "A button that allows users to confirm the process of saving their bank accounts for future payments. This button appears in a screen that allows users to select which bank accounts they want to use to pay for something."
        )
        connectAccountButton.isEnabled = false // disable by default
        connectAccountButton.addTarget(self, action: #selector(didSelectLinkAccountsButton), for: .touchUpInside)
        connectAccountButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            connectAccountButton.heightAnchor.constraint(equalToConstant: 56)
        ])
        return connectAccountButton
    }()

    init(
        isStripeDirect: Bool,
        businessName: String?,
        permissions: [StripeAPI.FinancialConnectionsAccount.Permissions],
        singleAccount: Bool,
        didSelectConnectAccount: @escaping () -> Void,
        didSelectMerchantDataAccessLearnMore: @escaping () -> Void
    ) {
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
                    font: .body(.small),
                    boldFont: .body(.smallEmphasized),
                    alignCenter: true,
                    didSelectLearnMore: didSelectMerchantDataAccessLearnMore
                ),
                connectAccountButton,
            ]
        )
        verticalStackView.axis = .vertical
        verticalStackView.spacing = 24
        addAndPinSubview(verticalStackView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func didSelectLinkAccountsButton() {
        didSelectConnectAccount()
    }

    func enableButton(_ enableButton: Bool) {
        connectAccountButton.isEnabled = enableButton
    }
}
