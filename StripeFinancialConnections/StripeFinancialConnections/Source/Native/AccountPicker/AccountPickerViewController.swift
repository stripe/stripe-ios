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

@available(iOSApplicationExtension, unavailable)
protocol AccountPickerViewControllerDelegate: AnyObject {
    func accountPickerViewController(
        _ viewController: AccountPickerViewController,
        didLinkAccounts linkedAccounts: [FinancialConnectionsPartnerAccount]
    )
}

enum AccountPickerType {
    case checkbox
    case radioButton
    case dropdown
}

@available(iOSApplicationExtension, unavailable)
final class AccountPickerViewController: UIViewController {
    
    private let dataSource: AccountPickerDataSource
    private let accountPickerType: AccountPickerType
    weak var delegate: AccountPickerViewControllerDelegate?
    private weak var accountPickerSelectionView: AccountPickerSelectionView?
    private var businessName: String? {
        return dataSource.manifest.businessName
    }
    
    private lazy var footerView: AccountPickerFooterView = {
        return AccountPickerFooterView(
            businessName: businessName,
            singleAccount: dataSource.manifest.singleAccount,
            didSelectLinkAccounts: { [weak self] in
                self?.didSelectLinkAccounts()
            }
        )
    }()
    
    init(dataSource: AccountPickerDataSource) {
        self.dataSource = dataSource
        self.accountPickerType = {
            if dataSource.authorizationSession.skipAccountSelection == true && dataSource.manifest.singleAccount && dataSource.authorizationSession.flow?.isOAuth() == true {
                return .dropdown
            } else {
                return dataSource.manifest.singleAccount ? .radioButton : .checkbox
            }
        }()
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
                    self.displayAccounts(accounts.data)
                case .failure(let error):
                    print(error) // TODO(kgaidis): handle all sorts of errors...
                }
                retreivingAccountsLoadingView.removeFromSuperview()
            }
    }
    
    private func displayAccounts(_ accounts: [FinancialConnectionsPartnerAccount]) {
        let accountPickerSelectionView = AccountPickerSelectionView(
            accountPickerType: accountPickerType,
            accounts: accounts,
            institution: dataSource.institution,
            delegate: self
        )
        self.accountPickerSelectionView = accountPickerSelectionView
        let contentViewPair = CreateContentView(
            headerView: CreateContentHeaderView(
                businessName: businessName,
                singleAccount: dataSource.manifest.singleAccount
            ),
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
        
        if accountPickerType == .dropdown {
            let tapOutsideOfDropdownGestureRecognizer = UITapGestureRecognizer(
                target: self,
                action: #selector(didTapOutsideOfDropdownControl)
            )
            contentViewPair.scrollView.addGestureRecognizer(tapOutsideOfDropdownGestureRecognizer)
        }
        
        // TODO(kgaidis): does this account for disabled accounts?
        // select an initial set of accounts for the user by default
        switch accountPickerType {
        case .checkbox:
            // select all accounts
            dataSource.updateSelectedAccounts(accounts)
        case .radioButton:
            if accounts.count == 1 {
                // select the one (and only) available account
                dataSource.updateSelectedAccounts(accounts)
            } else { // accounts.count >= 2
                // don't select any accounts (...let the user decide which one)
                dataSource.updateSelectedAccounts([])
            }
        case .dropdown:
            if accounts.count == 1 {
                // select the one (and only) available account
                dataSource.updateSelectedAccounts(accounts)
            } else { // accounts.count >= 2
                // don't select any accounts (...let the user decide which one)
                dataSource.updateSelectedAccounts([])
            }
        }
    }
    
    private func didSelectLinkAccounts() {
        let numberOfSelectedAccounts = dataSource.selectedAccounts.count
        let linkingAccountsLoadingView = ReusableInformationView(
            iconType: .loading,
            title: {
                if numberOfSelectedAccounts == 1 {
                    return STPLocalizedString("Linking account", "The title of the loading screen that appears when a user is in process of connecting their bank account to an application. Once the bank account is connected (or linked), the user will be able to use that bank account for payments.")
                } else {
                    return STPLocalizedString("Linking accounts", "The title of the loading screen that appears when a user is in process of connecting their bank accounts to an application. Once the bank accounts are connected (or linked), the user will be able to use those bank accounts for payments.")
                }
            }(),
            subtitle: {
                if numberOfSelectedAccounts == 1 {
                    if let businessName = businessName {
                        return String(format: STPLocalizedString("Please wait while your account is linked to %@ through Stripe.", "The subtitle/description of the loading screen that appears when a user is in process of connecting their bank account to an application. Once the bank account is connected (or linked), the user will be able to use the bank account for payments.  %@ will be replaced by the business name, for example, The Coca-Cola Company."), businessName)
                    } else {
                        return STPLocalizedString("Please wait while your account is linked to Stripe.", "The subtitle/description of the loading screen that appears when a user is in process of connecting their bank account to an application. Once the bank account is connected (or linked), the user will be able to use the bank account for payments.")
                    }
                } else { // multiple bank accounts (numberOfSelectedAccounts > 1)
                    if let businessName = businessName {
                        return String(format: STPLocalizedString("Please wait while your accounts are linked to %@ through Stripe.", "The subtitle/description of the loading screen that appears when a user is in process of connecting their bank accounts to an application. Once the bank accounts are connected (or linked), the user will be able to use those bank accounts for payments.  %@ will be replaced by the business name, for example, The Coca-Cola Company."), businessName)
                    } else {
                        return STPLocalizedString("Please wait while your accounts are linked to Stripe.", "The subtitle/description of the loading screen that appears when a user is in process of connecting their bank accounts to an application. Once the bank accounts are connected (or linked), the user will be able to use those bank accounts for payments.")
                    }
                }
            }()
        )
        view.addAndPinSubviewToSafeArea(linkingAccountsLoadingView)
        navigationItem.hidesBackButton = true
        
        dataSource
            .selectAuthSessionAccounts()
            .observe(on: .main) { [weak self] result in
                guard let self = self else { return }
                self.navigationItem.hidesBackButton = false // reset
                linkingAccountsLoadingView.removeFromSuperview()
                
                switch result {
                case .success(let linkedAccounts):
                    self.delegate?.accountPickerViewController(self, didLinkAccounts: linkedAccounts.data)
                case .failure(let error):
                    print(error) // TODO(kgaidis): show a fatal error
                }
            }
    }
    
    @objc private func didTapOutsideOfDropdownControl() {
        // hide the "dropdown picker view keyboard"
        view.endEditing(true)
    }
}

// MARK: - AccountPickerSelectionViewDelegate

@available(iOSApplicationExtension, unavailable)
extension AccountPickerViewController: AccountPickerSelectionViewDelegate {
    
    func accountPickerSelectionView(
        _ view: AccountPickerSelectionView,
        didSelectAccounts selectedAccounts: [FinancialConnectionsPartnerAccount]
    ) {
        dataSource.updateSelectedAccounts(selectedAccounts)
    }
}

// MARK: - AccountPickerDataSourceDelegate

@available(iOSApplicationExtension, unavailable)
extension AccountPickerViewController: AccountPickerDataSourceDelegate {
    func accountPickerDataSource(
        _ dataSource: AccountPickerDataSource,
        didSelectAccounts selectedAccounts: [FinancialConnectionsPartnerAccount]
    ) {
        footerView.didSelectAccounts(count: selectedAccounts.count)
        accountPickerSelectionView?.selectAccounts(selectedAccounts)
    }
}

// MARK: - Helpers

private func CreateContentView(
    headerView: UIView,
    accountPickerSelectionView: UIView
) -> (scrollView: UIScrollView, scrollViewContent: UIView) {
    
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
    
    let scrollView = UIScrollView()
    scrollView.addAndPinSubview(verticalStackView)

    return (scrollView, verticalStackView)
}

private func CreateContentHeaderView(businessName: String?, singleAccount: Bool) -> UIView {
    let titleLabel = UILabel()
    titleLabel.numberOfLines = 0
    if singleAccount {
        titleLabel.text = STPLocalizedString("Select an account", "The title of a screen that allows users to select which bank accounts they want to use to pay for something.")
    } else {
        titleLabel.text = STPLocalizedString("Select accounts", "The title of a screen that allows users to select which bank accounts they want to use to pay for something.")
    }
    titleLabel.font = .stripeFont(forTextStyle: .subtitle)
    titleLabel.textColor = UIColor.textPrimary
    titleLabel.textAlignment = .left
    
    let verticalStackView = UIStackView()
    verticalStackView.axis = .vertical
    verticalStackView.spacing = 8
    verticalStackView.addArrangedSubview(titleLabel)
    if singleAccount {
        let subtitleLabel = UILabel()
        subtitleLabel.numberOfLines = 0
        if let businessName = businessName {
            subtitleLabel.text = String(format: STPLocalizedString("%@ only needs one account at this time.", "A subtitle/description of a screen that allows users to select which bank accounts they want to use to pay for something. This text tries to portray that they only need to select one bank account. %@ will be filled with the business name, ex. Coca-Cola Company."), businessName)
        } else {
            subtitleLabel.text = STPLocalizedString("This merchant only needs one account at this time.", "A subtitle/description of a screen that allows users to select which bank accounts they want to use to pay for something. This text tries to portray that they only need to select one bank account.")
        }
        subtitleLabel.font = .stripeFont(forTextStyle: .body)
        subtitleLabel.textColor = UIColor.textSecondary
        subtitleLabel.textAlignment = .left
        verticalStackView.addArrangedSubview(subtitleLabel)
    }
    return verticalStackView
}
