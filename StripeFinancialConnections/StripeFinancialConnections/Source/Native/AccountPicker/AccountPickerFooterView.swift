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
    
    private let singleAccountButtonTitle = STPLocalizedString("Link account", "A button that allows users to confirm the process of saving their bank account for future payments. This button appears in a screen that allows users to select which bank accounts they want to use to pay for something.")
    private let multipleAccountButtonTitle = STPLocalizedString("Link accounts", "A button that allows users to confirm the process of saving their bank accounts for future payments. This button appears in a screen that allows users to select which bank accounts they want to use to pay for something.")
    
    private let singleAccount: Bool
    private let didSelectLinkAccounts: () -> Void
    
    private lazy var linkAccountsButton: Button = {
        let linkAccountsButton = Button(
            configuration: {
                var linkAccountsButtonConfiguration = Button.Configuration.primary()
                linkAccountsButtonConfiguration.font = .stripeFont(forTextStyle: .bodyEmphasized)
                linkAccountsButtonConfiguration.backgroundColor = .textBrand
                return linkAccountsButtonConfiguration
            }()
        )
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
        singleAccount: Bool,
        didSelectLinkAccounts: @escaping () -> Void
    ) {
        self.singleAccount = singleAccount
        self.didSelectLinkAccounts = didSelectLinkAccounts
        super.init(frame: .zero)
        
        let verticalStackView = UIStackView(
            arrangedSubviews: [
                CreateDataAccessDisclosureView(
                    isStripeDirect: isStripeDirect,
                    businessName: businessName,
                    permissions: permissions
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
        
        if numberOfAccountsSelected == 0 {
            if singleAccount {
                linkAccountsButton.title = singleAccountButtonTitle
            } else {
                linkAccountsButton.title = multipleAccountButtonTitle
            }
        } else if numberOfAccountsSelected == 1 {
            linkAccountsButton.title = singleAccountButtonTitle
        } else { // numberOfAccountsSelected > 1
            linkAccountsButton.title = multipleAccountButtonTitle
        }
    }
}

@available(iOSApplicationExtension, unavailable)
private func CreateDataAccessDisclosureView(
    isStripeDirect: Bool,
    businessName: String?,
    permissions: [StripeAPI.FinancialConnectionsAccount.Permissions]
) -> UIView {
    let stackView = UIStackView(
        arrangedSubviews: [
            MerchantDataAccessView(
                isStripeDirect: false,
                businessName: businessName,
                permissions: []
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
    stackView.layer.borderColor = UIColor.borderNeutral.cgColor
    stackView.layer.borderWidth = 1.0 / UIScreen.main.nativeScale
    return stackView
}
