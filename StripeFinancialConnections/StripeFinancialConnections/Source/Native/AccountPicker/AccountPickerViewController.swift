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
        didLinkAccounts linkedAccounts: [FinancialConnectionsPartnerAccount],
        skipToSuccess: Bool
    )
    func accountPickerViewControllerDidSelectAnotherBank(_ viewController: AccountPickerViewController)
    func accountPickerViewControllerDidSelectManualEntry(_ viewController: AccountPickerViewController)
    func accountPickerViewController(_ viewController: AccountPickerViewController, didReceiveTerminalError error: Error)
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
    private var didSelectAnotherBank: () -> Void {
        return { [weak self] in
            guard let self = self else { return }
            self.delegate?.accountPickerViewControllerDidSelectAnotherBank(self)
        }
    }
    // we only allow to retry account polling once
    private var allowAccountPollingRetry = true
    private var didSelectTryAgain: (() -> Void)? {
        return allowAccountPollingRetry ? { [weak self] in
            guard let self = self else { return }
            self.allowAccountPollingRetry = false
            self.showErrorView(nil)
            self.pollAuthSessionAccounts()
        } : nil
    }
    private var didSelectManualEntry: (() -> Void)? {
        return dataSource.manifest.allowManualEntry ? { [weak self] in
            guard let self = self else { return }
            self.delegate?.accountPickerViewControllerDidSelectManualEntry(self)
        } : nil
    }
    private var errorView: UIView?
    
    private lazy var footerView: AccountPickerFooterView = {
        return AccountPickerFooterView(
            isStripeDirect: dataSource.manifest.isStripeDirect ?? false,
            businessName: businessName,
            permissions: dataSource.manifest.permissions,
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
        pollAuthSessionAccounts()
    }
    
    private func pollAuthSessionAccounts() {
        // Load accounts
        let retreivingAccountsLoadingView = ReusableInformationView(
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
                case .success(let accountsPayload):
                    let accounts = accountsPayload.data
                    if accounts.isEmpty {
                        // if there were no accounts returned, API should have thrown an error
                        // ...handle it here since API did not throw error
                        self.showAccountLoadErrorView() // "API returned an empty list of accounts"
                    } else if self.dataSource.authorizationSession.skipAccountSelection ?? false {
                        self.delegate?.accountPickerViewController(self, didLinkAccounts: accounts, skipToSuccess: true)
                    } else if
                        self.dataSource.manifest.singleAccount,
                        self.dataSource.authorizationSession.institutionSkipAccountSelection ?? false,
                        accounts.count == 1
                    {
                        // the user saw an OAuth account selection screen and selected
                        // just one to send back in a single-account context. treat these as if
                        // we had done account selection, and submit.
                        self.dataSource.updateSelectedAccounts(accounts)
                        self.didSelectLinkAccounts()
                    } else {
                        let (enabledAccounts, disabledAccounts) = accounts
                            .reduce(
                                ([FinancialConnectionsPartnerAccount](), [FinancialConnectionsDisabledPartnerAccount]())
                            ) { accountsTuple, account in
                                if let paymentMethodType = self.dataSource.manifest.paymentMethodType, !account.supportedPaymentMethodTypes.contains(paymentMethodType) {
                                    return (
                                        accountsTuple.0,
                                        accountsTuple.1 + [
                                            FinancialConnectionsDisabledPartnerAccount(
                                                account: account,
                                                disableReason: {
                                                    if paymentMethodType == .usBankAccount {
                                                        return STPLocalizedString("Must be checking or savings account", "A message that appears in a screen that allows users to select which bank accounts they want to use to pay for something. It notifies the user that their bank account is not supported.")
                                                    } else if paymentMethodType == .link {
                                                        return STPLocalizedString("Must be US checking account", "A message that appears in a screen that allows users to select which bank accounts they want to use to pay for something. It notifies the user that their bank account is not supported.")
                                                    } else {
                                                        return STPLocalizedString("Unsuppported account", "A message that appears in a screen that allows users to select which bank accounts they want to use to pay for something. It notifies the user that their bank account is not supported.")
                                                    }
                                                }()
                                            )
                                        ]
                                    )
                                } else {
                                    return (
                                        accountsTuple.0 + [account],
                                        accountsTuple.1
                                    )
                                }
                            }
                        self.displayAccounts(enabledAccounts, disabledAccounts)
                    }
                case .failure(let error):
                    if
                        let error = error as? StripeError,
                        case .apiError(let apiError) = error,
                        let extraFields = apiError.allResponseFields["extra_fields"] as? [String:Any],
                        let reason = extraFields["reason"] as? String,
                        reason == "no_supported_payment_method_type_accounts_found",
                        let numberOfIneligibleAccounts = extraFields["total_accounts_count"] as? Int,
                        // it should never happen, but if numberOfIneligibleAccounts is < 1, we should
                        // show "AccountLoadErrorView."
                        numberOfIneligibleAccounts > 0
                    {
                        let errorView = AccountPickerNoAccountEligibleErrorView(
                            institution: self.dataSource.institution,
                            bussinessName: self.businessName,
                            institutionSkipAccountSelection: self.dataSource.authorizationSession.institutionSkipAccountSelection ?? false,
                            numberOfIneligibleAccounts: numberOfIneligibleAccounts,
                            paymentMethodType: self.dataSource.manifest.paymentMethodType ?? .usBankAccount,
                            didSelectAnotherBank: self.didSelectAnotherBank,
                            didSelectEnterBankDetailsManually: self.didSelectManualEntry
                        )
                        // the user will never enter this instance of `AccountPickerViewController`
                        // again...they can only choose manual entry or go through "ResetFlow"
                        self.showErrorView(errorView)
                    } else {
                        // if we didn't get that specific error back, we don't know what's wrong. could the be
                        // aggregator, could be Stripe.
                        self.showAccountLoadErrorView()
                    }
                }
                retreivingAccountsLoadingView.removeFromSuperview()
            }
    }
    
    private func displayAccounts(
        _ enabledAccounts: [FinancialConnectionsPartnerAccount],
        _ disabledAccounts: [FinancialConnectionsDisabledPartnerAccount]
    ) {
        let accountPickerSelectionView = AccountPickerSelectionView(
            accountPickerType: accountPickerType,
            enabledAccounts: enabledAccounts,
            disabledAccounts: disabledAccounts,
            institution: dataSource.institution,
            delegate: self
        )
        self.accountPickerSelectionView = accountPickerSelectionView
        let paneLayoutView = PaneWithHeaderLayoutView(
            title: {
                if dataSource.manifest.singleAccount {
                    return STPLocalizedString("Select an account", "The title of a screen that allows users to select which bank accounts they want to use to pay for something.")
                } else {
                    return STPLocalizedString("Select accounts", "The title of a screen that allows users to select which bank accounts they want to use to pay for something.")
                }
            }(),
            subtitle: {
                if dataSource.manifest.singleAccount {
                    if let businessName = businessName {
                        return String(format: STPLocalizedString("%@ only needs one account at this time.", "A subtitle/description of a screen that allows users to select which bank accounts they want to use to pay for something. This text tries to portray that they only need to select one bank account. %@ will be filled with the business name, ex. Coca-Cola Company."), businessName)
                    } else {
                        return  STPLocalizedString("This merchant only needs one account at this time.", "A subtitle/description of a screen that allows users to select which bank accounts they want to use to pay for something. This text tries to portray that they only need to select one bank account.")
                    }
                } else {
                    return nil // no subtitle
                }
            }(),
            contentView: accountPickerSelectionView,
            footerView: footerView
        )
        paneLayoutView.addTo(view: view)
        
        if accountPickerType == .dropdown {
            let tapOutsideOfDropdownGestureRecognizer = UITapGestureRecognizer(
                target: self,
                action: #selector(didTapOutsideOfDropdownControl)
            )
            paneLayoutView.scrollView.addGestureRecognizer(tapOutsideOfDropdownGestureRecognizer)
        }
        
        // TODO(kgaidis): does this account for disabled accounts?
        // select an initial set of accounts for the user by default
        switch accountPickerType {
        case .checkbox:
            // select all accounts
            dataSource.updateSelectedAccounts(enabledAccounts)
        case .radioButton:
            if enabledAccounts.count == 1 {
                // select the one (and only) available account
                dataSource.updateSelectedAccounts(enabledAccounts)
            } else { // accounts.count >= 2
                // don't select any accounts (...let the user decide which one)
                dataSource.updateSelectedAccounts([])
            }
        case .dropdown:
            if enabledAccounts.count == 1 {
                // select the one (and only) available account
                dataSource.updateSelectedAccounts(enabledAccounts)
            } else { // accounts.count >= 2
                // don't select any accounts (...let the user decide which one)
                dataSource.updateSelectedAccounts([])
            }
        }
    }
    
    private func showAccountLoadErrorView() {
        let errorView = AccountPickerAccountLoadErrorView(
            institution: dataSource.institution,
            didSelectAnotherBank: didSelectAnotherBank,
            didSelectTryAgain: didSelectTryAgain,
            didSelectEnterBankDetailsManually: didSelectManualEntry
        )
        self.showErrorView(errorView)
    }
    
    private func showErrorView(_ errorView: UIView?) {
        if let errorView = errorView {
            view.addAndPinSubview(errorView)
        } else {
            // clear last error
            self.errorView?.removeFromSuperview()
        }
        self.errorView = errorView
        navigationItem.hidesBackButton = (errorView != nil)
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
                    self.delegate?.accountPickerViewController(
                        self,
                        didLinkAccounts: linkedAccounts.data,
                        skipToSuccess: false
                    )
                case .failure(let error):
                    self.delegate?.accountPickerViewController(self, didReceiveTerminalError: error)
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
