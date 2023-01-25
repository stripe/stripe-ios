//
//  SuccessViewController.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 8/12/22.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
import UIKit

@available(iOSApplicationExtension, unavailable)
protocol SuccessViewControllerDelegate: AnyObject {
    func successViewControllerDidSelectLinkMoreAccounts(_ viewController: SuccessViewController)
    func successViewControllerDidSelectDone(_ viewController: SuccessViewController)
}

@available(iOSApplicationExtension, unavailable)
final class SuccessViewController: UIViewController {

    private let dataSource: SuccessDataSource
    weak var delegate: SuccessViewControllerDelegate?

    init(dataSource: SuccessDataSource) {
        self.dataSource = dataSource
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .customBackgroundColor
        navigationItem.hidesBackButton = true

        let paneWithHeaderLayoutView = PaneWithHeaderLayoutView(
            icon: .view(SuccessIconView()),
            title: STPLocalizedString(
                "Success!",
                "The title of the success screen that appears when a user is done with the process of connecting their bank account to an application. Now that the bank account is connected (or linked), the user will be able to use the bank account for payments."
            ),
            subtitle: CreateSubtitleText(
                businessName: dataSource.manifest.businessName,
                isLinkingOneAccount: (dataSource.linkedAccounts.count == 1)
            ),
            contentView: SuccessBodyView(
                institution: dataSource.institution,
                linkedAccounts: dataSource.linkedAccounts,
                isStripeDirect: dataSource.manifest.isStripeDirect ?? false,
                businessName: dataSource.manifest.businessName,
                permissions: dataSource.manifest.permissions,
                accountDisconnectionMethod: dataSource.manifest.accountDisconnectionMethod,
                isEndUserFacing: dataSource.manifest.isEndUserFacing ?? false,
                analyticsClient: dataSource.analyticsClient,
                didSelectDisconnectYourAccounts: { [weak self] in
                    guard let self = self else { return }
                    self.dataSource
                        .analyticsClient
                        .log(
                            eventName: "click.disconnect_link",
                            parameters: ["pane": FinancialConnectionsSessionManifest.NextPane.success.rawValue]
                        )
                },
                didSelectMerchantDataAccessLearnMore: { [weak self] in
                    guard let self = self else { return }
                    self.dataSource
                        .analyticsClient
                        .logMerchantDataAccessLearnMore(pane: .success)
                }
            ),
            footerView: SuccessFooterView(
                didSelectDone: { [weak self] footerView in
                    guard let self = self else { return }
                    // we NEVER set isLoading to `false` because
                    // we will always close the Auth Flow
                    footerView.setIsLoading(true)
                    self.dataSource
                        .analyticsClient
                        .log(
                            eventName: "click.done",
                            parameters: ["pane": FinancialConnectionsSessionManifest.NextPane.success.rawValue]
                        )
                    self.delegate?.successViewControllerDidSelectDone(self)
                },
                didSelectLinkAnotherAccount: dataSource.showLinkMoreAccountsButton
                    ? { [weak self] in
                        guard let self = self else { return }
                        self.dataSource
                            .analyticsClient
                            .log(
                                eventName: "click.link_another_account",
                                parameters: ["pane": FinancialConnectionsSessionManifest.NextPane.success.rawValue]
                            )
                        self.delegate?.successViewControllerDidSelectLinkMoreAccounts(self)
                    } : nil
            )
        )
        paneWithHeaderLayoutView.addTo(view: view)

        dataSource
            .analyticsClient
            .logPaneLoaded(pane: .success)
    }
}

private func CreateSubtitleText(businessName: String?, isLinkingOneAccount: Bool) -> String {
    if isLinkingOneAccount {
        if let businessName = businessName {
            return String(
                format: STPLocalizedString(
                    "Your account was successfully linked to %@ through Stripe.",
                    "The subtitle/description of the success screen that appears when a user is done with the process of connecting their bank account to an application. Now that the bank account is connected (or linked), the user will be able to use the bank account for payments. %@ will be replaced by the business name, for example, The Coca-Cola Company."
                ),
                businessName
            )
        } else {
            return STPLocalizedString(
                "Your account was successfully linked to Stripe.",
                "The subtitle/description of the success screen that appears when a user is done with the process of connecting their bank account to an application. Now that the bank account is connected (or linked), the user will be able to use the bank account for payments."
            )
        }
    } else {  // multiple bank accounts
        if let businessName = businessName {
            return String(
                format: STPLocalizedString(
                    "Your accounts were successfully linked to %@ through Stripe.",
                    "The subtitle/description of the success screen that appears when a user is done with the process of connecting their bank accounts to an application. Now that the bank accounts are connected (or linked), the user will be able to use those bank accounts for payments. %@ will be replaced by the business name, for example, The Coca-Cola Company."
                ),
                businessName
            )
        } else {
            return STPLocalizedString(
                "Your accounts were successfully linked to Stripe.",
                "The subtitle/description of the success screen that appears when a user is done with the process of connecting their bank accounts to an application. Now that the bank accounts are connected (or linked), the user will be able to use those bank accounts for payments."
            )
        }
    }
}
