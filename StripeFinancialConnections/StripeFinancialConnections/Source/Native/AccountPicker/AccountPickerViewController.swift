//
//  AccountPickerViewController.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 8/5/22.
//

import Foundation
import SafariServices
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
import UIKit

protocol AccountPickerViewControllerDelegate: AnyObject {
    func accountPickerViewController(
        _ viewController: AccountPickerViewController,
        didSelectAccounts selectedAccounts: [FinancialConnectionsPartnerAccount],
        nextPane: FinancialConnectionsSessionManifest.NextPane,
        customSuccessPaneMessage: String?,
        saveToLinkWithStripeSucceeded: Bool?
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

enum AccountPickerSelectionType {
    case single
    case multiple
}

final class AccountPickerViewController: UIViewController {

    private let dataSource: AccountPickerDataSource
    private let selectionType: AccountPickerSelectionType
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
            dataAccessNotice: dataSource.accountPickerPane?.dataAccessNotice,
            singleAccount: dataSource.manifest.singleAccount,
            appearance: dataSource.manifest.appearance,
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
                self.didSelectLinkAccounts(isSkipAccountSelection: false)
            },
            didSelectMerchantDataAccessLearnMore: { [weak self] url in
                guard let self = self else { return }
                self.dataSource
                    .analyticsClient
                    .logMerchantDataAccessLearnMore(pane: .accountPicker)

                if let dataAccessNotice = self.dataSource.dataAccessNotice {
                    let dataAccessNoticeViewController = DataAccessNoticeViewController(
                        dataAccessNotice: dataAccessNotice,
                        appearance: self.dataSource.manifest.appearance,
                        didSelectUrl: { [weak self] url in
                            guard let self = self else { return }
                            AuthFlowHelpers.handleURLInTextFromBackend(
                                url: url,
                                pane: .accountPicker,
                                analyticsClient: self.dataSource.analyticsClient,
                                handleURL: { _, _ in }
                            )
                        }
                    )
                    dataAccessNoticeViewController.present(on: self)
                } else {
                    SFSafariViewController.present(url: url)
                }
            }
        )
    }()

    init(dataSource: AccountPickerDataSource) {
        self.dataSource = dataSource
        self.selectionType = dataSource.manifest.singleAccount ? .single : .multiple
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
        view.backgroundColor = FinancialConnectionsAppearance.Colors.background
        pollAuthSessionAccounts()
    }

    private func pollAuthSessionAccounts() {
        let retreivingAccountsLoadingView = RetrieveAccountsLoadingView(
            institutionIconUrl: dataSource.institution.icon?.default
        )
        view.addAndPinSubviewToSafeArea(retreivingAccountsLoadingView)

        let pollingStartDate = Date()
        dataSource
            .pollAuthSessionAccounts()
            .observe(on: .main) { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success(let accountsPayload):
                    self.dataSource
                        .analyticsClient
                        .logPaneLoaded(pane: .accountPicker)

                    let accounts = accountsPayload.data
                    guard !accounts.isEmpty else {
                        // if there were no accounts returned, API should have thrown an error
                        // ...handle it here since API did not throw error
                        self.showAccountLoadErrorView(
                            error: FinancialConnectionsSheetError.unknown(
                                debugDescription: "API returned an empty list of accounts"
                            )
                        )
                        return
                    }

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

                    // note that this uses ?? instead of ||, we do NOT want to skip account selection
                    // if EITHER of these are true, we only want to skip account selection when
                    //  `accountsPayload.skipAccountSelection` is true, OR `accountsPayload.skipAccountSelection` nil
                    // AND `authSession.skipAccountSelection` is true
                    let skipAccountSelection = (accountsPayload.skipAccountSelection ?? self.dataSource.authSession.skipAccountSelection ?? false)
                    if skipAccountSelection {
                        let selectableAccounts = accounts.filter(\.allowSelectionNonOptional)
                        if self.dataSource.manifest.singleAccount {
                            if let firstEnabledAccount = selectableAccounts.first {
                                self.dataSource.updateSelectedAccounts([firstEnabledAccount])
                            } else {
                                self.showNoEligibleAccountsErrorView(
                                    numberOfIneligibleAccounts: accounts.count,
                                    error: FinancialConnectionsSheetError.unknown(
                                        debugDescription: "No eligible accounts found"
                                    )
                                )
                            }
                        } else {
                            self.dataSource.updateSelectedAccounts(selectableAccounts)
                        }
                        self.didSelectLinkAccounts(isSkipAccountSelection: true)
                    } else if
                        self.dataSource.manifest.singleAccount,
                        self.dataSource.authSession.institutionSkipAccountSelection ?? false,
                        accounts.count == 1
                    {
                        // the user saw an OAuth account selection screen and selected
                        // just one to send back in a single-account context. treat these as if
                        // we had done account selection, and submit.
                        self.dataSource.updateSelectedAccounts(accounts)
                        self.didSelectLinkAccounts(isSkipAccountSelection: true)
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
                        self.showNoEligibleAccountsErrorView(
                            numberOfIneligibleAccounts: numberOfIneligibleAccounts,
                            error: error
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

    private func showNoEligibleAccountsErrorView(numberOfIneligibleAccounts: Int, error: Error) {
        let errorView = AccountPickerNoAccountEligibleErrorView(
            institution: self.dataSource.institution,
            bussinessName: self.businessName,
            institutionSkipAccountSelection: self.dataSource.authSession.institutionSkipAccountSelection
                ?? false,
            numberOfIneligibleAccounts: numberOfIneligibleAccounts,
            paymentMethodType: self.dataSource.manifest.paymentMethodType ?? .usBankAccount,
            appearance: self.dataSource.manifest.appearance,
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
    }

    private func displayAccounts(
        _ enabledAccounts: [FinancialConnectionsPartnerAccount],
        _ disabledAccounts: [FinancialConnectionsPartnerAccount]
    ) {
        let accountPickerSelectionView = AccountPickerSelectionView(
            selectionType: selectionType,
            enabledAccounts: enabledAccounts,
            disabledAccounts: disabledAccounts,
            institution: dataSource.institution,
            appearance: dataSource.manifest.appearance,
            delegate: self
        )
        self.accountPickerSelectionView = accountPickerSelectionView

        let paneLayoutView = PaneLayoutView(
            contentView: PaneLayoutView.createContentView(
                iconView: {
                    if let institutionIconUrl = dataSource.institution.icon?.default {
                        let institutionIconView = InstitutionIconView()
                        institutionIconView.setImageUrl(institutionIconUrl)
                        return institutionIconView
                    } else {
                        return nil
                    }
                }(),
                title: {
                    if dataSource.manifest.singleAccount {
                        return STPLocalizedString(
                            "Select account",
                            "The title of a screen that allows users to select which bank accounts they want to use to pay for something."
                        )
                    } else {
                        return STPLocalizedString(
                            "Select accounts",
                            "The title of a screen that allows users to select which bank accounts they want to use to pay for something."
                        )
                    }
                }(),
                subtitle: nil,
                contentView: accountPickerSelectionView
            ),
            footerView: footerView
        )
        paneLayoutView.addTo(view: view)

        switch selectionType {
        case .multiple:
            // select all accounts
            dataSource.updateSelectedAccounts(enabledAccounts)
        case .single:
            if let firstAccount = enabledAccounts.first {
                dataSource.updateSelectedAccounts([firstAccount])
            } else {
                // defensive programming; it should never happen that we have 0 accounts
                dataSource.updateSelectedAccounts([])
            }
        }
        dataSource
            .analyticsClient
            .log(
                eventName: "account_picker.accounts_auto_selected",
                parameters: [
                    "account_ids": dataSource.selectedAccounts.map({ $0.id }),
                    "is_single_account": (selectionType == .single),
                ],
                pane: .accountPicker
            )
    }

    private func showAccountLoadErrorView(error: Error) {
        let errorView = AccountPickerAccountLoadErrorView(
            institution: dataSource.institution,
            appearance: dataSource.manifest.appearance,
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

    private func didSelectLinkAccounts(isSkipAccountSelection: Bool) {
        footerView.startLoading()
        // the `footerView` only shows loading view on the button,
        // so we need to prevent interactions elsewhere on the
        // screen while its loading
        view.isUserInteractionEnabled = false

        dataSource
            .analyticsClient
            .log(
                eventName: "account_picker.accounts_submitted",
                parameters: [
                    "account_ids": dataSource.selectedAccounts.map({ $0.id }),
                    "is_skip_account_selection": isSkipAccountSelection,
                ],
                pane: .accountPicker
            )

        dataSource
            .selectAuthSessionAccounts()
            .observe(on: .main) { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success(let linkedAccounts):
                    // the response from the API is the list of accounts that were selected, 
                    // with the `linked_account_id` populated.
                    //
                    // in cases of skip-account-selection in multi-account flows,
                    // the API returns no accounts since no "new" accounts were linked,
                    // so we need to fall back to the list of selected accounts
                    let selectedAccounts: [FinancialConnectionsPartnerAccount]
                    if linkedAccounts.data.count >= 1 {
                        selectedAccounts = linkedAccounts.data
                    } else {
                        selectedAccounts = self.dataSource.selectedAccounts
                    }

                    // for data flows (external_api), where the user is already
                    // determined to be a Link consumer, we need to take an
                    // additional step of saving the accounts to Link
                    if
                        self.dataSource.manifest.isNetworkingUserFlow == true,
                        // make sure the current user is a Link consumer
                        self.dataSource.manifest.accountholderIsLinkConsumer == true,
                        // make sure this is not a payment flow; in payment flows,
                        // the AttachLinkedPaymentAccount handles saving to link
                        !self.dataSource.manifest.shouldAttachLinkedPaymentMethod,
                        selectedAccounts.count > 0,
                        let consumerSessionClientSecret = self.dataSource.consumerSessionClientSecret
                    {
                        self.dataSource.saveToLink(
                            accounts: selectedAccounts,
                            consumerSessionClientSecret: consumerSessionClientSecret
                        )
                        .observe { [weak self] result in
                            guard let self = self else { return }

                            let saveToLinkWithStripeSucceeded: Bool
                            let customSuccessPaneMessage: String?
                            switch result {
                            case .success(let _customSuccessPaneMessage):
                                saveToLinkWithStripeSucceeded = true
                                customSuccessPaneMessage = _customSuccessPaneMessage
                            case .failure(let error):
                                saveToLinkWithStripeSucceeded = false
                                customSuccessPaneMessage = nil
                                self.dataSource
                                    .analyticsClient
                                    .logUnexpectedError(
                                        error,
                                        errorName: "SaveToLinkError",
                                        pane: .accountPicker
                                    )
                            }
                            self.delegate?.accountPickerViewController(
                                self,
                                didSelectAccounts: selectedAccounts,
                                nextPane: .success,
                                customSuccessPaneMessage: customSuccessPaneMessage,
                                saveToLinkWithStripeSucceeded: saveToLinkWithStripeSucceeded
                            )
                        }
                    }
                    // for networking payment flows, and networking data flows where
                    // user will go through Link sign-up (or Link sign-in verification),
                    // we do not need to call `saveAccountsToLink`
                    else {
                        self.delegate?.accountPickerViewController(
                            self,
                            didSelectAccounts: selectedAccounts,
                            nextPane: linkedAccounts.nextPane,
                            customSuccessPaneMessage: nil,
                            saveToLinkWithStripeSucceeded: nil
                        )
                    }
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
        switch selectionType {
        case .single:
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
        case .multiple:
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
        FeedbackGeneratorAdapter.selectionChanged()
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
