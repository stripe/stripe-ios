//
//  AccountPickerViewController.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 8/5/22.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
import UIKit

protocol AccountPickerViewControllerDelegate: AnyObject {
    func accountPickerViewController(
        _ viewController: AccountPickerViewController,
        didSelectAccounts selectedAccounts: [FinancialConnectionsPartnerAccount]
    )
    func accountPickerViewControllerDidSelectAnotherBank(_ viewController: AccountPickerViewController)
    func accountPickerViewControllerDidSelectManualEntry(_ viewController: AccountPickerViewController)
    func accountPickerViewController(
        _ viewController: AccountPickerViewController,
        didReceiveTerminalError error: Error
    )
    func accountPickerViewController(
        _ viewController: AccountPickerViewController,
        didReceiveEvent event: FinancialConnectionsEvent
    )
}

enum AccountPickerType {
    case checkbox
    case radioButton
}

final class AccountPickerViewController: UIViewController {

    private let dataSource: AccountPickerDataSource
    private let accountPickerType: AccountPickerType
    // a special case where some institutions have an
    // account picker as part of their bank auth
    // flow, so we give special treatment
    private let institutionHasAccountPicker: Bool
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
        return allowAccountPollingRetry
            ? { [weak self] in
                guard let self = self else { return }
                self.allowAccountPollingRetry = false
                self.showErrorView(nil)
                self.pollAuthSessionAccounts()
            } : nil
    }
    private var didSelectManualEntry: (() -> Void)? {
        return (dataSource.manifest.allowManualEntry && !dataSource.reduceManualEntryProminenceInErrors)
            ? { [weak self] in
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
            institutionHasAccountPicker: institutionHasAccountPicker,
            didSelectLinkAccounts: { [weak self] in
                guard let self = self else {
                    return
                }
                self.dataSource
                    .analyticsClient
                    .log(
                        eventName: "click.link_accounts",
                        pane: .accountPicker
                    )
                self.delegate?.accountPickerViewController(
                    self,
                    didReceiveEvent: FinancialConnectionsEvent(name: .accountsSelected)
                )
                self.didSelectLinkAccounts()
            },
            didSelectMerchantDataAccessLearnMore: { [weak self] in
                guard let self = self else { return }
                self.dataSource
                    .analyticsClient
                    .logMerchantDataAccessLearnMore(pane: .accountPicker)
            }
        )
    }()

    init(dataSource: AccountPickerDataSource) {
        self.dataSource = dataSource
        self.accountPickerType = dataSource.manifest.singleAccount ? .radioButton : .checkbox
        self.institutionHasAccountPicker =
            (dataSource.authSession.institutionSkipAccountSelection == true && dataSource.manifest.singleAccount
                && dataSource.authSession.isOauthNonOptional)
        super.init(nibName: nil, bundle: nil)
        dataSource.delegate = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // account picker ALWAYS hides the back button
        navigationItem.hidesBackButton = true
        view.backgroundColor = .customBackgroundColor
        pollAuthSessionAccounts()
    }

    private func pollAuthSessionAccounts() {
        // Load accounts
        let retreivingAccountsLoadingView = buildRetrievingAccountsView()
        view.addAndPinSubviewToSafeArea(retreivingAccountsLoadingView)

        let pollingStartDate = Date()
        dataSource
            .pollAuthSessionAccounts()
            .observe(on: .main) { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success(let accountsPayload):
                    let accounts = accountsPayload.data
                    let shouldSkipAccountSelection = accountsPayload.skipAccountSelection ?? self.dataSource.authSession.skipAccountSelection ?? false
                    if !accounts.isEmpty {
                        // the API is expected to never return 0 accounts
                        self.dataSource
                            .analyticsClient
                            .log(
                                eventName: "polling.accounts.success",
                                parameters: [
                                    "duration": Date().timeIntervalSince(pollingStartDate).milliseconds,
                                    "authSessionId": self.dataSource.authSession.id,
                                ],
                                pane: .accountPicker
                            )
                    }
                    self.dataSource
                        .analyticsClient
                        .logPaneLoaded(pane: .accountPicker)

                    if accounts.isEmpty {
                        // if there were no accounts returned, API should have thrown an error
                        // ...handle it here since API did not throw error
                        self.showAccountLoadErrorView(
                            error: FinancialConnectionsSheetError.unknown(
                                debugDescription: "API returned an empty list of accounts"
                            )
                        )
                    } else if shouldSkipAccountSelection {
                        self.delegate?.accountPickerViewController(
                            self,
                            didSelectAccounts: accounts
                        )
                    } else if self.dataSource.manifest.singleAccount,
                        self.dataSource.authSession.institutionSkipAccountSelection ?? false,
                        accounts.count == 1
                    {
                        // the user saw an OAuth account selection screen and selected
                        // just one to send back in a single-account context. treat these as if
                        // we had done account selection, and submit.
                        self.dataSource.updateSelectedAccounts(accounts)
                        self.didSelectLinkAccounts()
                    } else {
                        let (enabledAccounts, disabledAccounts) =
                            accounts
                            .reduce(
                                ([FinancialConnectionsPartnerAccount](), [FinancialConnectionsPartnerAccount]())
                            ) { accountsTuple, account in
                                if !account.allowSelectionNonOptional {
                                    return (
                                        accountsTuple.0,
                                        accountsTuple.1 + [account]
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
                    if let error = error as? StripeError,
                        case .apiError(let apiError) = error,
                        let extraFields = apiError.allResponseFields["extra_fields"] as? [String: Any],
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
                            institutionSkipAccountSelection: self.dataSource.authSession.institutionSkipAccountSelection
                                ?? false,
                            numberOfIneligibleAccounts: numberOfIneligibleAccounts,
                            paymentMethodType: self.dataSource.manifest.paymentMethodType ?? .usBankAccount,
                            didSelectAnotherBank: self.didSelectAnotherBank
                        )
                        // the user will never enter this instance of `AccountPickerViewController`
                        // again...they can only choose manual entry or go through "ResetFlow"
                        self.showErrorView(errorView)
                        self.dataSource
                            .analyticsClient
                            .logExpectedError(
                                error,
                                errorName: "AccountNoneEligibleForPaymentMethodError",
                                pane: .accountPicker
                            )
                    } else {
                        // if we didn't get that specific error back, we don't know what's wrong. could the be
                        // aggregator, could be Stripe.
                        self.showAccountLoadErrorView(error: error)
                    }
                }
                retreivingAccountsLoadingView.removeFromSuperview()
            }
    }

    private func displayAccounts(
        _ enabledAccounts: [FinancialConnectionsPartnerAccount],
        _ disabledAccounts: [FinancialConnectionsPartnerAccount]
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
                if self.institutionHasAccountPicker {
                    return STPLocalizedString(
                        "Confirm your account",
                        "The title of a screen that allows users to select which bank accounts they want to use to pay for something."
                    )
                } else {
                    if dataSource.manifest.singleAccount {
                        return STPLocalizedString(
                            "Select an account",
                            "The title of a screen that allows users to select which bank accounts they want to use to pay for something."
                        )
                    } else {
                        return STPLocalizedString(
                            "Select accounts",
                            "The title of a screen that allows users to select which bank accounts they want to use to pay for something."
                        )
                    }
                }
            }(),
            subtitle: {
                if institutionHasAccountPicker {
                    return STPLocalizedString(
                        "Select the account you'd like to link.",
                        "A subtitle/description of a screen that allows users to select which bank accounts they want to use to pay for something. This text tries to portray that they only need to select one bank account."
                    )
                } else {
                    return nil  // no subtitle
                }
            }(),
            contentView: accountPickerSelectionView,
            footerView: footerView
        )
        paneLayoutView.addTo(view: view)

        switch accountPickerType {
        case .checkbox:
            // select all accounts
            dataSource.updateSelectedAccounts(enabledAccounts)
        case .radioButton:
            if let firstAccount = enabledAccounts.first {
                dataSource.updateSelectedAccounts([firstAccount])
            } else {
                // defensive programming; it should never happen that we have 0 accounts
                dataSource.updateSelectedAccounts([])
            }
        }
    }

    private func showAccountLoadErrorView(error: Error) {
        let errorView = AccountPickerAccountLoadErrorView(
            institution: dataSource.institution,
            didSelectAnotherBank: didSelectAnotherBank,
            didSelectTryAgain: didSelectTryAgain,
            didSelectEnterBankDetailsManually: didSelectManualEntry
        )
        showErrorView(errorView)
        dataSource
            .analyticsClient
            .logExpectedError(
                error,
                errorName: "AccountLoadError",
                pane: .accountPicker
            )
    }

    private func showErrorView(_ errorView: UIView?) {
        if let errorView = errorView {
            view.addAndPinSubview(errorView)
        } else {
            // clear last error
            self.errorView?.removeFromSuperview()
        }
        self.errorView = errorView
    }

    private func didSelectLinkAccounts() {
        let numberOfSelectedAccounts = dataSource.selectedAccounts.count
        let linkingAccountsLoadingView = LinkingAccountsLoadingView(
            numberOfSelectedAccounts: numberOfSelectedAccounts,
            businessName: businessName
        )
        view.addAndPinSubviewToSafeArea(linkingAccountsLoadingView)

        dataSource
            .selectAuthSessionAccounts()
            .observe(on: .main) { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success(let linkedAccounts):
                    self.delegate?.accountPickerViewController(
                        self,
                        didSelectAccounts: linkedAccounts.data
                    )
                case .failure(let error):
                    self.dataSource
                        .analyticsClient
                        .logUnexpectedError(
                            error,
                            errorName: "SelectAuthSessionAccountsError",
                            pane: .accountPicker
                        )
                    self.delegate?.accountPickerViewController(self, didReceiveTerminalError: error)
                }
            }
    }

    private func logAccountSelectOrDeselect(selectedAccounts: [FinancialConnectionsPartnerAccount]) {
        let isSelect: Bool? // false when deselected, and nil when event shouldn't be sent
        let accountId: String?
        switch accountPickerType {
        case .radioButton:
            // user deselected an account by selecting the same row
            if selectedAccounts.isEmpty {
                isSelect = false
                accountId = dataSource.selectedAccounts.first?.id
            }
            // user selected a new account
            else {
                isSelect = true
                accountId = selectedAccounts.first?.id
            }
        case .checkbox:
            // if user selects or deselects more than two accounts at the same time, we assume user pressed
            // "All accounts" which we have decided to exclude due to V3 changes
            let pressedAllAccountsButton = (abs(selectedAccounts.count - dataSource.selectedAccounts.count) >= 2)
            if !pressedAllAccountsButton {
                if selectedAccounts.count > dataSource.selectedAccounts.count {
                    // selected a new, additional account
                    isSelect = true
                    accountId = selectedAccounts
                        .filter({ newSelectedAccount in
                            return !dataSource.selectedAccounts.contains(where: { $0.id == newSelectedAccount.id })
                        })
                        .first?
                        .id
                }
                // selectedAccounts.count < dataSource.selectedAccounts.count
                else {
                    // deselected an account
                    isSelect = false
                    accountId = dataSource.selectedAccounts
                        .filter({ oldSelectedAccount in
                            return !selectedAccounts.contains(where: { $0.id == oldSelectedAccount.id })
                        })
                        .first?
                        .id
                }
            } else {
                isSelect = nil
                accountId = nil
            }
        }
        if let isSelect = isSelect, let accountId = accountId {
            dataSource
                .analyticsClient
                .log(
                    eventName: isSelect ? "click.account_picker.account_selected" : "click.account_picker.account_unselected",
                    parameters: [
                        "account": accountId,
                        "is_single_account": dataSource.manifest.singleAccount,
                    ],
                    pane: .accountPicker
                )
        }
    }
}

// MARK: - AccountPickerSelectionViewDelegate

extension AccountPickerViewController: AccountPickerSelectionViewDelegate {

    func accountPickerSelectionView(
        _ view: AccountPickerSelectionView,
        didSelectAccounts selectedAccounts: [FinancialConnectionsPartnerAccount]
    ) {
        logAccountSelectOrDeselect(selectedAccounts: selectedAccounts)
        dataSource.updateSelectedAccounts(selectedAccounts)
    }
}

// MARK: - AccountPickerDataSourceDelegate

extension AccountPickerViewController: AccountPickerDataSourceDelegate {
    func accountPickerDataSource(
        _ dataSource: AccountPickerDataSource,
        didSelectAccounts selectedAccounts: [FinancialConnectionsPartnerAccount]
    ) {
        footerView.didSelectAccounts(count: selectedAccounts.count)
        accountPickerSelectionView?.selectAccounts(selectedAccounts)
    }
}
