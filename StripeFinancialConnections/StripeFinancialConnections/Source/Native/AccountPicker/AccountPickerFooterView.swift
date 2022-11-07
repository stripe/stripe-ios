//
//  AccountPickerFooterView.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 8/10/22.
//

import Foundation
import UIKit
@_spi(STP) import StripeUICore

@available(iOSApplicationExtension, unavailable)
final class AccountPickerFooterView: UIView {
    
    private let didSelectLinkAccounts: () -> Void
    
    private lazy var linkAccountsButton: Button = {
        let linkAccountsButton = Button(configuration: .financialConnectionsPrimary)
        linkAccountsButton.title = STPLocalizedString("Confirm", "A button that allows users to confirm the process of saving their bank accounts for future payments. This button appears in a screen that allows users to select which bank accounts they want to use to pay for something.")
        linkAccountsButton.addTarget(self, action: #selector(didSelectLinkAccountsButton), for: .touchUpInside)
        linkAccountsButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            linkAccountsButton.heightAnchor.constraint(equalToConstant: 56),
        ])
        return linkAccountsButton
    }()
    
    init(
        isStripeDirect: Bool,
        businessName: String?,
        permissions: [StripeAPI.FinancialConnectionsAccount.Permissions],
        didSelectLinkAccounts: @escaping () -> Void,
        didSelectMerchantDataAccessLearnMore: @escaping () -> Void
    ) {
        self.didSelectLinkAccounts = didSelectLinkAccounts
        super.init(frame: .zero)
        
        let verticalStackView = UIStackView(
            arrangedSubviews: [
                CreateDataAccessDisclosureView(
                    isStripeDirect: isStripeDirect,
                    businessName: businessName,
                    permissions: permissions,
                    didSelectLearnMore: didSelectMerchantDataAccessLearnMore
                ),
                linkAccountsButton,
            ]
        )
        verticalStackView.axis = .vertical
        verticalStackView.spacing = 20
        addSubview(verticalStackView)
        addAndPinSubviewToSafeArea(verticalStackView)
        
        didSelectAccounts(count: 0) // set the button title
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc private func didSelectLinkAccountsButton() {
        didSelectLinkAccounts()
    }
    
    func didSelectAccounts(count numberOfAccountsSelected: Int) {
        linkAccountsButton.isEnabled = (numberOfAccountsSelected > 0)
        linkAccountsButton.alpha = linkAccountsButton.isEnabled ? 1.0 : 0.5
    }
}

@available(iOSApplicationExtension, unavailable)
private func CreateDataAccessDisclosureView(
    isStripeDirect: Bool,
    businessName: String?,
    permissions: [StripeAPI.FinancialConnectionsAccount.Permissions],
    didSelectLearnMore: @escaping () -> Void
) -> UIView {
    let stackView = UIStackView(
        arrangedSubviews: [
            MerchantDataAccessView(
                isStripeDirect: isStripeDirect,
                businessName: businessName,
                permissions: permissions,
                didSelectLearnMore: didSelectLearnMore
            )
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
