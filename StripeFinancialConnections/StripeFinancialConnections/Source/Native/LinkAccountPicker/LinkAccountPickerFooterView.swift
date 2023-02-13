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
        let linkAccountsButton = Button(configuration: .financialConnectionsPrimary)
        linkAccountsButton.addTarget(self, action: #selector(didSelectLinkAccountsButton), for: .touchUpInside)
        linkAccountsButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            linkAccountsButton.heightAnchor.constraint(equalToConstant: 56)
        ])
        return linkAccountsButton
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
                CreateDataAccessDisclosureView(
                    isStripeDirect: isStripeDirect,
                    businessName: businessName,
                    permissions: permissions,
                    didSelectLearnMore: didSelectMerchantDataAccessLearnMore
                ),
                connectAccountButton,
            ]
        )
        verticalStackView.axis = .vertical
        verticalStackView.spacing = 20
        addSubview(verticalStackView)
        addAndPinSubviewToSafeArea(verticalStackView)

        didSelectAccounts(count: 0)  // set the button title
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func didSelectLinkAccountsButton() {
        didSelectConnectAccount()
    }

    func didSelectAccounts(count numberOfAccountsSelected: Int) {
        connectAccountButton.isEnabled = (numberOfAccountsSelected > 0)
        
        connectAccountButton.title = STPLocalizedString(
            "Connect account",
            "A button that allows users to confirm the process of saving their bank accounts for future payments. This button appears in a screen that allows users to select which bank accounts they want to use to pay for something."
        )
    }
}

@available(iOSApplicationExtension, unavailable)
private func CreateDataAccessDisclosureView(
    isStripeDirect: Bool,
    businessName: String?,
    permissions: [StripeAPI.FinancialConnectionsAccount.Permissions],
    didSelectLearnMore: @escaping () -> Void
) -> UIView {
    let stackView = HitTestStackView(
        arrangedSubviews: [
            MerchantDataAccessView(
                isStripeDirect: isStripeDirect,
                businessName: businessName,
                permissions: permissions,
                didSelectLearnMore: didSelectLearnMore
            ),
        ]
    )
    stackView.isLayoutMarginsRelativeArrangement = true
    stackView.directionalLayoutMargins = NSDirectionalEdgeInsets(
        top: 10,
        leading: 12,
        bottom: 10,
        trailing: 12
    )
    stackView.backgroundColor = .backgroundContainer
    stackView.layer.cornerRadius = 8
    return stackView
}
