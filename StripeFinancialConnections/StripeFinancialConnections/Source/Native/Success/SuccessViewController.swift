//
//  SuccessViewController.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 8/12/22.
//

import Foundation
import UIKit
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore

@available(iOSApplicationExtension, unavailable)
protocol SuccessViewControllerDelegate: AnyObject {
    func successViewControllerDidSelectLinkMoreAccounts(_ viewController: SuccessViewController)
    func successViewController(
        _ viewController: SuccessViewController,
        didCompleteSession session: StripeAPI.FinancialConnectionsSession
    )
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
            icon: .view(SuccesIconView()),
            title: STPLocalizedString("Success!", "The title of the success screen that appears when a user is done with the process of connecting their bank account to an application. Now that the bank account is connected (or linked), the user will be able to use the bank account for payments."),
            subtitle: CreateSubtitleText(
                businessName: dataSource.manifest.businessName,
                isLinkingOneAccount: (dataSource.linkedAccounts.count <= 1)
            ),
            contentView: SuccessBodyView(
                institution: dataSource.institution,
                linkedAccounts: dataSource.linkedAccounts,
                isStripeDirect: dataSource.manifest.isStripeDirect ?? false,
                businessName: dataSource.manifest.businessName,
                permissions: dataSource.manifest.permissions
            ),
            footerView: SuccessFooterView(
                didSelectDone: { [weak self] in
                    self?.didSelectDone()
                },
                didSelectLinkAnotherAccount: dataSource.showLinkMoreAccountsButton ? { [weak self] in
                    guard let self = self else { return }
                    self.delegate?.successViewControllerDidSelectLinkMoreAccounts(self)
                } : nil
            )
        )
        paneWithHeaderLayoutView.addTo(view: view)
    }
    
    private func didSelectDone() {
        dataSource.completeFinancialConnectionsSession()
            .observe(on: .main) { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success(let session):
                    self.delegate?.successViewController(self, didCompleteSession: session)
                case .failure(let error):
                    print(error) // TODO(kgaidis): handle error properly
                }
            }
    }
}

private func CreateSubtitleText(businessName: String?, isLinkingOneAccount: Bool) -> String {
    if isLinkingOneAccount {
        if let businessName = businessName {
            return String(format: STPLocalizedString("Your account was successfully linked to %@ through Stripe.", "The subtitle/description of the success screen that appears when a user is done with the process of connecting their bank account to an application. Now that the bank account is connected (or linked), the user will be able to use the bank account for payments. %@ will be replaced by the business name, for example, The Coca-Cola Company."), businessName)
        } else {
            return STPLocalizedString("Your account was successfully linked to Stripe.", "The subtitle/description of the success screen that appears when a user is done with the process of connecting their bank account to an application. Now that the bank account is connected (or linked), the user will be able to use the bank account for payments.")
        }
    } else { // multiple bank accounts
        if let businessName = businessName {
            return String(format: STPLocalizedString("Your accounts were successfully linked to %@ through Stripe.", "The subtitle/description of the success screen that appears when a user is done with the process of connecting their bank accounts to an application. Now that the bank accounts are connected (or linked), the user will be able to use those bank accounts for payments. %@ will be replaced by the business name, for example, The Coca-Cola Company."), businessName)
        } else {
            return STPLocalizedString("Your accounts were successfully linked to Stripe.", "The subtitle/description of the success screen that appears when a user is done with the process of connecting their bank accounts to an application. Now that the bank accounts are connected (or linked), the user will be able to use those bank accounts for payments.")
        }
    }
}
