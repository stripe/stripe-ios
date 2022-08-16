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
        manifest: FinancialConnectionsSessionManifest
    ) {
        super.init(frame: .zero)
        let verticalStackView = UIStackView(
            arrangedSubviews: [
                CreateInformationBoxView(
                    accountsListView: SuccessAccountListView(
                        institution: institution,
                        linkedAccounts: linkedAccounts
                    ),
                    dataDisclosureView: CreateDataAccessDisclosureView(
                        businessName: manifest.businessName
                    )
                ),
                CreateDisconnectAccountLabel()
            ]
        )
        verticalStackView.axis = .vertical
        verticalStackView.spacing = 12
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
private func CreateDataAccessDisclosureView(businessName: String?) -> UIView {
    let separatorView = UIView()
    separatorView.backgroundColor = .borderNeutral
    separatorView.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
        separatorView.heightAnchor.constraint(equalToConstant: 1 / UIScreen.main.nativeScale),
    ])
    
    // TODO(kgaidis): make the 'Data accessible to X' bold and localize/make-it-reusable as this also appears in success screen. `DataAccessText`
    let textFront: String
    if let businessName = businessName {
        textFront = "Data accessible to \(businessName):"
    } else {
        textFront = "Data accessible to this business:"
    }
    // Data accessible to this business:
    let text = "\(textFront) Account ownership details, account details through Stripe. [Learn more](https://support.stripe.com/user/questions/what-data-does-stripe-access-from-my-linked-financial-account)"
    let dataAccessLabel = ClickableLabel()
    dataAccessLabel.setText(
        text,
        font: .stripeFont(forTextStyle: .captionTight),
        linkFont: .stripeFont(forTextStyle: .captionTightEmphasized)
    )
    
    let verticalStackView = UIStackView(
        arrangedSubviews: [
            separatorView,
            dataAccessLabel,
        ]
    )
    verticalStackView.spacing = 11
    verticalStackView.axis = .vertical
    return verticalStackView
}

@available(iOSApplicationExtension, unavailable)
private func CreateDisconnectAccountLabel() -> UIView {
    let disconnectAccountLabel = ClickableLabel()
    disconnectAccountLabel.setText(
        "You can [disconnect your account](https://support.stripe.com/user/how-do-i-disconnect-my-linked-financial-account) any time.",
        font: .stripeFont(forTextStyle: .captionTight),
        linkFont: .stripeFont(forTextStyle: .captionTightEmphasized)
    )
    return disconnectAccountLabel
}
