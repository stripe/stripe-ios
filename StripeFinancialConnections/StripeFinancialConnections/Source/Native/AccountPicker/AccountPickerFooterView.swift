//
//  AccountPickerFooterView.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 8/10/22.
//

import Foundation
import UIKit
@_spi(STP) import StripeUICore

final class AccountPickerFooterView: UIView {
    
    private let didSelectLinkAccounts: () -> Void
    
    init(
        institutionName: String, // or merchant
        didSelectLinkAccounts: @escaping () -> Void
    ) {
        self.didSelectLinkAccounts = didSelectLinkAccounts
        super.init(frame: .zero)
        
        let linkAccountsButton = Button(
            configuration: {
                var linkAccountsButtonConfiguration = Button.Configuration.primary()
                linkAccountsButtonConfiguration.font = .stripeFont(forTextStyle: .bodyEmphasized)
                linkAccountsButtonConfiguration.backgroundColor = .textBrand
                return linkAccountsButtonConfiguration
            }()
        )
        linkAccountsButton.title = "Link account(s)"
        linkAccountsButton.addTarget(self, action: #selector(didSelectLinkAccountsButton), for: .touchUpInside)
        linkAccountsButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            linkAccountsButton.heightAnchor.constraint(equalToConstant: 56),
        ])
        
        let verticalStackView = UIStackView(
            arrangedSubviews: [
                linkAccountsButton
            ]
        )
        verticalStackView.isLayoutMarginsRelativeArrangement = true
        verticalStackView.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 20, leading: 24, bottom: 24, trailing: 24)
        addSubview(verticalStackView)
        
        addAndPinSubviewToSafeArea(verticalStackView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc private func didSelectLinkAccountsButton() {
        didSelectLinkAccounts()
    }
}
