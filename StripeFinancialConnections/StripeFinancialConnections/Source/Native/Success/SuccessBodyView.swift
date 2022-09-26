//
//  SuccessContentView.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 8/15/22.
//

import Foundation
import UIKit
@_spi(STP) import StripeUICore

@available(iOSApplicationExtension, unavailable)
final class SuccessBodyView: UIView {
    
    init(
        institution: FinancialConnectionsInstitution,
        linkedAccounts: [FinancialConnectionsPartnerAccount],
        isStripeDirect: Bool,
        businessName: String?,
        permissions: [StripeAPI.FinancialConnectionsAccount.Permissions]
    ) {
        super.init(frame: .zero)
        let verticalStackView = UIStackView()
        verticalStackView.axis = .vertical
        verticalStackView.spacing = 12
        
        if linkedAccounts.count > 0 {
            verticalStackView.addArrangedSubview(
                CreateInformationBoxView(
                    accountsListView: SuccessAccountListView(
                        institution: institution,
                        linkedAccounts: linkedAccounts
                    ),
                    dataDisclosureView: CreateDataAccessDisclosureView(
                        isStripeDirect: isStripeDirect,
                        businessName: businessName,
                        permissions: permissions
                    )
                )
            )
        }
        verticalStackView.addArrangedSubview(CreateDisconnectAccountLabel())
        
        addAndPinSubview(verticalStackView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

@available(iOSApplicationExtension, unavailable)
private func CreateInformationBoxView(
    accountsListView: UIView,
    dataDisclosureView: UIView
) -> UIView {
    let informationBoxVerticalStackView = UIStackView(
        arrangedSubviews: [
            accountsListView,
            dataDisclosureView,
        ]
    )
    informationBoxVerticalStackView.axis = .vertical
    informationBoxVerticalStackView.spacing = 16
    informationBoxVerticalStackView.isLayoutMarginsRelativeArrangement = true
    informationBoxVerticalStackView.directionalLayoutMargins = NSDirectionalEdgeInsets(
        top: 12,
        leading: 12,
        bottom: 12,
        trailing: 12
    )
    informationBoxVerticalStackView.backgroundColor = .backgroundContainer
    informationBoxVerticalStackView.layer.cornerRadius = 8
    return informationBoxVerticalStackView
}

@available(iOSApplicationExtension, unavailable)
private func CreateDataAccessDisclosureView(
    isStripeDirect: Bool,
    businessName: String?,
    permissions: [StripeAPI.FinancialConnectionsAccount.Permissions]
) -> UIView {
    let separatorView = UIView()
    separatorView.backgroundColor = .borderNeutral
    separatorView.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
        separatorView.heightAnchor.constraint(equalToConstant: 1 / UIScreen.main.nativeScale),
    ])
    
    let verticalStackView = UIStackView(
        arrangedSubviews: [
            separatorView,
            MerchantDataAccessView(
                isStripeDirect: isStripeDirect,
                businessName: businessName,
                permissions: permissions
            ),
        ]
    )
    verticalStackView.axis = .vertical
    verticalStackView.spacing = 11
    return verticalStackView
}

@available(iOSApplicationExtension, unavailable)
private func CreateDisconnectAccountLabel() -> UIView { // TODO(kgaidis): localize this string or fetch from backend
    let disconnectAccountLabel = ClickableLabel()
    disconnectAccountLabel.setText(
        "You can [disconnect your account](https://support.stripe.com/user/how-do-i-disconnect-my-linked-financial-account) any time.",
        font: .stripeFont(forTextStyle: .captionTight),
        linkFont: .stripeFont(forTextStyle: .captionTightEmphasized)
    )
    return disconnectAccountLabel
}
