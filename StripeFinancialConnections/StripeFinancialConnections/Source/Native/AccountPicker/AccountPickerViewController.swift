//
//  AccountPickerViewController.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 8/5/22.
//

import Foundation
import UIKit
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore

protocol AccountPickerViewControllerDelegate: AnyObject {
    
}

final class AccountPickerViewController: UIViewController {
    
    private let dataSource: AccountPickerDataSource
    weak var delegate: AccountPickerViewControllerDelegate?
    
    init(dataSource: AccountPickerDataSource) {
        self.dataSource = dataSource
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .customBackgroundColor

        // Load accounts
        let retreivingAccountsLoadingView = ReusableInformationView( // TODO(kgaidis): remove [test] language once we move this loading screen away from InstitutionPicker
            iconType: .loading,
            title: STPLocalizedString("Retrieving accounts", "The title of the loading screen that appears when a user just logged into their bank account, and now is waiting for their bank accounts to load. Once the bank accounts are loaded, user will be able to pick the bank account they want to to use for things like payments."),
            subtitle: STPLocalizedString("Please wait while we retrieve your accounts.", "The subtitle/description of the loading screen that appears when a user just logged into their bank account, and now is waiting for their bank accounts to load. Once the bank accounts are loaded, user will be able to pick the bank account they want to to use for things like payments.")
        )
        view.addAndPinSubviewToSafeArea(retreivingAccountsLoadingView)

        dataSource
            .pollAuthSessionAccounts()
            .observe(on: .main) { result in
                switch result {
                case .success(let accounts):
                    // TODO(kgaidis): Stripe.js does more logic to handle things based off HTTP status (ex. maybe we want to skip account selection stage)
                    self.displayAccounts(accounts)
                case .failure(let error):
                    print(error) // TODO(kgaidis): handle all sorts of errors...
                }
                retreivingAccountsLoadingView.removeFromSuperview()
            }
    }
    
    private func displayAccounts(_ accounts: FinancialConnectionsAuthorizationSessionAccounts) {
        print(accounts)
    }
}
