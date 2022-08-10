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

enum AccountPickerType {
    case single
    // TODO(kgaidis): there's  two types of single select (radio button + dropdown)
    case multi
}

final class AccountPickerViewController: UIViewController {
    
    private let dataSource: AccountPickerDataSource
    private let type: AccountPickerType
    weak var delegate: AccountPickerViewControllerDelegate?
    private weak var accountPickerSelectionView: AccountPickerSelectionView?
    
    private lazy var footerView: AccountPickerFooterView = {
        return AccountPickerFooterView(
            institutionName: "CashApp",
            didSelectLinkAccounts: {
            
            }
        )
    }()
    
    init(dataSource: AccountPickerDataSource) {
        self.dataSource = dataSource
        self.type = .multi // TODO(kgaidis): configure based off manifest info
        super.init(nibName: nil, bundle: nil)
        dataSource.delegate = self
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
            .observe(on: .main) { [weak self] result in
                guard let self = self else { return }
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
        
        let accountPickerSelectionView = AccountPickerSelectionView(
            type: type,
            accounts: accounts.data,
            delegate: self
        )
        self.accountPickerSelectionView = accountPickerSelectionView
        
        let contentViewPair = CreateContentView(
            headerView: CreateContentHeaderView(isSingleAccount: true),
            accountPickerSelectionView: accountPickerSelectionView
        )
        let verticalStackView = UIStackView(
            arrangedSubviews: [
                contentViewPair.scrollView,
                footerView,
            ]
        )
        verticalStackView.spacing = 0
        verticalStackView.axis = .vertical
        view.addAndPinSubviewToSafeArea(verticalStackView)
        
        // ensure that content ScrollView is bound to view's width
        contentViewPair.scrollViewContent.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        
        // select accounts
        switch type {
        case .single:
            fatalError("not implemented")
        case .multi:
            // select all accounts by default
            dataSource.selectedAccounts = accounts.data
        }
    }
}


// MARK: - AccountPickerSelectionViewDelegate

extension AccountPickerViewController: AccountPickerSelectionViewDelegate {
    
    func accountPickerSelectionView(
        _ view: AccountPickerSelectionView,
        didSelectAccounts selectedAccounts: [FinancialConnectionsPartnerAccount]
    ) {
        dataSource.selectedAccounts = selectedAccounts
    }
}

// MARK: - AccountPickerDataSourceDelegate

extension AccountPickerViewController: AccountPickerDataSourceDelegate {
    func accountPickerDataSource(
        _ dataSource: AccountPickerDataSource,
        didSelectAccounts selectedAccounts: [FinancialConnectionsPartnerAccount]
    ) {
        footerView.linkAccountsButton.isEnabled = !selectedAccounts.isEmpty
        accountPickerSelectionView?.selectAccounts(selectedAccounts)
    }
}

// MARK: - Helpers

private func CreateContentView(
    headerView: UIView,
    accountPickerSelectionView: UIView
) -> (scrollView: UIScrollView, scrollViewContent: UIView) {
    
    let scrollView = UIScrollView()
    
    let verticalStackView = UIStackView(
        arrangedSubviews: [
            headerView,
            accountPickerSelectionView
        ]
    )
    verticalStackView.axis = .vertical
    verticalStackView.spacing = 24
    verticalStackView.isLayoutMarginsRelativeArrangement = true
    verticalStackView.directionalLayoutMargins = NSDirectionalEdgeInsets(
        top: 16,
        leading: 24,
        bottom: 16,
        trailing: 24
    )
    
    scrollView.addAndPinSubview(verticalStackView)

    return (scrollView, verticalStackView)
}

private func CreateContentHeaderView(isSingleAccount: Bool) -> UIView {
    
    let titleLabel = UILabel()
    titleLabel.numberOfLines = 0
    titleLabel.text = "Select an account" // or "Select accounts"
    titleLabel.font = .stripeFont(forTextStyle: .subtitle)
    titleLabel.textColor = UIColor.textPrimary
    titleLabel.textAlignment = .left
    
    let verticalStackView = UIStackView()
    verticalStackView.axis = .vertical
    verticalStackView.spacing = 8
    
    verticalStackView.addArrangedSubview(titleLabel)
    if isSingleAccount {
        let subtitleLabel = UILabel()
        subtitleLabel.numberOfLines = 0
        subtitleLabel.text = "[Merchant] only needs one account at this time."
        subtitleLabel.font = .stripeFont(forTextStyle: .body)
        subtitleLabel.textColor = UIColor.textSecondary
        subtitleLabel.textAlignment = .left
        verticalStackView.addArrangedSubview(subtitleLabel)
    }
    
    return verticalStackView
}
