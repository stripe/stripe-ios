//
//  SuccessContentView.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 8/15/22.
//

import Foundation
import SafariServices
@_spi(STP) import StripeUICore
import UIKit

final class SuccessBodyView: HitTestView {

    init(
        institution: FinancialConnectionsInstitution,
        linkedAccounts: [FinancialConnectionsPartnerAccount],
        isStripeDirect: Bool,
        businessName: String?,
        permissions: [StripeAPI.FinancialConnectionsAccount.Permissions],
        accountDisconnectionMethod: FinancialConnectionsSessionManifest.AccountDisconnectionMethod?,
        isEndUserFacing: Bool,
        isNetworking: Bool,
        analyticsClient: FinancialConnectionsAnalyticsClient,
        didSelectDisconnectYourAccounts: @escaping () -> Void,
        didSelectMerchantDataAccessLearnMore: @escaping () -> Void
    ) {
        super.init(frame: .zero)
        let verticalStackView = HitTestStackView()
        verticalStackView.axis = .vertical
        verticalStackView.spacing = 12

        if !linkedAccounts.isEmpty {
            verticalStackView.addArrangedSubview(
                CreateInformationBoxView(
                    accountsListView: SuccessAccountListView(
                        institution: institution,
                        linkedAccounts: linkedAccounts
                    ),
                    dataDisclosureView: CreateDataAccessDisclosureView(
                        isStripeDirect: isStripeDirect,
                        businessName: businessName,
                        permissions: permissions,
                        isNetworking: isNetworking,
                        didSelectLearnMore: didSelectMerchantDataAccessLearnMore
                    )
                )
            )
        }
        verticalStackView.addArrangedSubview(
            CreateDisconnectAccountLabel(
                isLinkingOneAccount: (linkedAccounts.count == 1),
                accountDisconnectionMethod: accountDisconnectionMethod ?? .email,
                isEndUserFacing: isEndUserFacing,
                didSelectDisconnectYourAccounts: didSelectDisconnectYourAccounts
            )
        )

        addAndPinSubview(verticalStackView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private func CreateInformationBoxView(
    accountsListView: UIView,
    dataDisclosureView: UIView
) -> UIView {
    let informationBoxVerticalStackView = HitTestStackView(
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

private func CreateDataAccessDisclosureView(
    isStripeDirect: Bool,
    businessName: String?,
    permissions: [StripeAPI.FinancialConnectionsAccount.Permissions],
    isNetworking: Bool,
    didSelectLearnMore: @escaping () -> Void
) -> UIView {
    let separatorView = UIView()
    separatorView.backgroundColor = .borderNeutral
    separatorView.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
        separatorView.heightAnchor.constraint(equalToConstant: 1 / stp_screenNativeScale)
    ])

    let verticalStackView = HitTestStackView(
        arrangedSubviews: [
            separatorView,
            MerchantDataAccessView(
                isStripeDirect: isStripeDirect,
                businessName: businessName,
                permissions: permissions,
                isNetworking: isNetworking,
                font: .label(.small),
                boldFont: .label(.smallEmphasized),
                alignCenter: false,
                didSelectLearnMore: didSelectLearnMore
            ),
        ]
    )
    verticalStackView.axis = .vertical
    verticalStackView.spacing = 11
    return verticalStackView
}

private func CreateDisconnectAccountLabel(
    isLinkingOneAccount: Bool,
    accountDisconnectionMethod: FinancialConnectionsSessionManifest.AccountDisconnectionMethod,
    isEndUserFacing: Bool,
    didSelectDisconnectYourAccounts: @escaping () -> Void
) -> UIView {
    let disconnectYourAccountLocalizedString: String = {
        if isLinkingOneAccount {
            return STPLocalizedString(
                "disconnect your account",
                "One part of larger text 'You can disconnect your account at any time.' The text instructs the user that the bank accounts they linked to Stripe, can always be disconnected later. The 'disconnect your account' part is clickable and will show user a support website."
            )
        } else {
            return STPLocalizedString(
                "disconnect your accounts",
                "One part of larger text 'You can disconnect your account at any time.' The text instructs the user that the bank accounts they linked to Stripe, can always be disconnected later. The 'disconnect your account' part is clickable and will show user a support website."
            )
        }
    }()
    let fullLocalizedString = STPLocalizedString(
        "You can %@ at any time.",
        "The text instructs the user that the bank accounts they linked to Stripe, can always be disconnected later. '%@' will be replaced by 'disconnect your account', to form a full string: 'You can disconnect your account at any time.'."
    )
    let disconnectionUrlString = DisconnectionURLString(
        accountDisconnectionMethod: accountDisconnectionMethod,
        isEndUserFacing: isEndUserFacing
    )

    let disconnectAccountLabel = AttributedTextView(
        font: .body(.small),
        boldFont: .body(.smallEmphasized),
        linkFont: .body(.smallEmphasized),
        textColor: .textSecondary
    )
    disconnectAccountLabel.setText(
        String(format: fullLocalizedString, "[\(disconnectYourAccountLocalizedString)](\(disconnectionUrlString))"),
        action: { url in
            SFSafariViewController.present(url: url)
            didSelectDisconnectYourAccounts()
        }
    )
    return disconnectAccountLabel
}

private func DisconnectionURLString(
    accountDisconnectionMethod: FinancialConnectionsSessionManifest.AccountDisconnectionMethod,
    isEndUserFacing: Bool
) -> String {
    switch accountDisconnectionMethod {
    case .support:
        if isEndUserFacing {
            return "https://support.stripe.com/user/how-do-i-disconnect-my-linked-financial-account"
        } else {
            return "https://support.stripe.com/how-to-disconnect-a-linked-financial-account"
        }
    case .dashboard:
        return "https://dashboard.stripe.com/settings/linked-accounts"
    case .link:
        return
            "https://support.link.co/questions/connecting-your-bank-account#how-do-i-disconnect-my-connected-bank-account"
    case .unparsable:
        fallthrough
    case .email:
        return "https://support.stripe.com/contact"
    }
}
