//
//  LinkLinkAccountPickerViewController.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 2/13/23.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
import UIKit

protocol LinkAccountPickerViewControllerDelegate: AnyObject {
    func linkAccountPickerViewController(
        _ viewController: LinkAccountPickerViewController,
        didRequestNextPane nextPane: FinancialConnectionsSessionManifest.NextPane,
        hideBackButtonOnNextPane: Bool
    )

    func linkAccountPickerViewController(
        _ viewController: LinkAccountPickerViewController,
        didRequestNextPane nextPane: FinancialConnectionsSessionManifest.NextPane,
        customSuccessPaneCaption: String,
        customSuccessPaneSubCaption: String
    )

    func linkAccountPickerViewController(
        _ viewController: LinkAccountPickerViewController,
        didSelectAccounts selectedAccounts: [FinancialConnectionsPartnerAccount]
    )

    func linkAccountPickerViewController(
        _ viewController: LinkAccountPickerViewController,
        requestedPartnerAuthWithInstitution institution: FinancialConnectionsInstitution
    )

    func linkAccountPickerViewController(
        _ viewController: LinkAccountPickerViewController,
        requestedBankAuthRepairWithInstitution institution: FinancialConnectionsInstitution,
        forAuthorization authorization: String
    )

    func linkAccountPickerViewController(
        _ viewController: LinkAccountPickerViewController,
        didReceiveTerminalError error: Error
    )

    func linkAccountPickerViewController(
        _ viewController: LinkAccountPickerViewController,
        didReceiveEvent event: FinancialConnectionsEvent
    )
}

final class LinkAccountPickerViewController: UIViewController {

    private let dataSource: LinkAccountPickerDataSource
    weak var delegate: LinkAccountPickerViewControllerDelegate?
    private var businessName: String? {
        return dataSource.manifest.businessName
    }
    private lazy var contentStackView: UIStackView = {
        let verticalStackView = UIStackView(
            arrangedSubviews: [
                // this sets up an initial `headerView` and `bodyView`
                // for the loading state
                PaneLayoutView.createHeaderView(
                    iconView: nil,
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
                    }()
                ),
                // `createBodyView` adds extra padding
                // around the loading view
                PaneLayoutView.createBodyView(
                    text: nil,
                    contentView: LinkAccountPickerLoadingView()
                ),
            ]
        )
        verticalStackView.axis = .vertical
        verticalStackView.spacing = 0
        return verticalStackView
    }()
    private lazy var footerContainerView: UIView = {
        return UIView()
    }()
    private weak var bodyView: LinkAccountPickerBodyView?
    private weak var footerView: LinkAccountPickerFooterView?

    init(dataSource: LinkAccountPickerDataSource) {
        self.dataSource = dataSource
        super.init(nibName: nil, bundle: nil)
        dataSource.delegate = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // link account picker ALWAYS hides the back button
        navigationItem.hidesBackButton = true
        view.backgroundColor = FinancialConnectionsAppearance.Colors.background

        let paneLayoutView =  PaneLayoutView(
            contentView: contentStackView,
            footerView: footerContainerView
        )
        paneLayoutView.addTo(view: view)

        fetchNetworkedAccounts()
    }

    private func fetchNetworkedAccounts() {
        dataSource
            .fetchNetworkedAccounts()
            .observe { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success(let networkedAccountsResponse):
                    if networkedAccountsResponse.data.isEmpty {
                        let nextPaneOnAddAccount = dataSource.nextPaneOnAddAccount ?? .institutionPicker
                        // Don't show a back button on the next pane so they don't return to an empty list.
                        self.delegate?.linkAccountPickerViewController(
                            self,
                            didRequestNextPane: nextPaneOnAddAccount,
                            hideBackButtonOnNextPane: true
                        )
                    } else if let returningNetworkingUserAccountPicker = networkedAccountsResponse.display?.text?.returningNetworkingUserAccountPicker {
                        self.display(
                            partnerAccounts: networkedAccountsResponse.data,
                            networkingAccountPicker: returningNetworkingUserAccountPicker
                        )
                    } else {
                        self.delegate?.linkAccountPickerViewController(
                            self,
                            didReceiveTerminalError: FinancialConnectionsSheetError.unknown(
                                debugDescription: "Tried fetching networked accounts but received no display parameter."
                            )
                        )
                    }
                case .failure(let error):
                    self.dataSource
                        .analyticsClient
                        .logUnexpectedError(
                            error,
                            errorName: "FetchNetworkedAccountsError",
                            pane: .linkAccountPicker
                        )
                    self.delegate?.linkAccountPickerViewController(
                        self,
                        didRequestNextPane: .institutionPicker,
                        hideBackButtonOnNextPane: false
                    )
                }
            }
    }

    private func display(
        partnerAccounts: [FinancialConnectionsPartnerAccount],
        networkingAccountPicker: FinancialConnectionsNetworkingAccountPicker
    ) {
        let accountTuples: [FinancialConnectionsAccountTuple] = ZipAccounts(
            partnerAccounts: partnerAccounts,
            accountPickerAccounts: networkingAccountPicker.accounts
        )

        let bodyView = LinkAccountPickerBodyView(
            accountTuples: accountTuples,
            addNewAccount: networkingAccountPicker.addNewAccount,
            appearance: dataSource.manifest.appearance
        )
        bodyView.delegate = self
        self.bodyView = bodyView

        // clear the stack
        contentStackView.subviews.forEach { subview in
            subview.removeFromSuperview()
        }
        contentStackView.addArrangedSubview(
            PaneLayoutView.createHeaderView(
                iconView: nil,
                title: networkingAccountPicker.title
            )
        )
        contentStackView.addArrangedSubview(
            PaneLayoutView.createBodyView(
                text: nil,
                contentView: bodyView
            )
        )

        let footerView = LinkAccountPickerFooterView(
            defaultCta: networkingAccountPicker.defaultCta,
            aboveCta: networkingAccountPicker.aboveCta,
            singleAccount: dataSource.manifest.singleAccount,
            appearance: dataSource.manifest.appearance,
            didSelectConnectAccount: { [weak self] in
                guard let self = self else {
                    return
                }
                self.didSelectConnectAccounts()
            },
            didSelectMerchantDataAccessLearnMore: { [weak self] _ in
                guard let self = self else { return }
                self.dataSource
                    .analyticsClient
                    .logMerchantDataAccessLearnMore(pane: .linkAccountPicker)

                if let dataAccessNotice = self.dataSource.dataAccessNotice {
                    let dataAccessNoticeViewController = DataAccessNoticeViewController(
                        dataAccessNotice: dataAccessNotice,
                        appearance: dataSource.manifest.appearance,
                        didSelectUrl: { [weak self] url in
                            guard let self = self else { return }
                            self.didSelectURLInTextFromBackend(url)
                        }
                    )
                    dataAccessNoticeViewController.present(on: self)
                }
            }
        )
        self.footerView = footerView
        footerContainerView.addAndPinSubview(footerView)

        let firstSelectableAccount = accountTuples.first { accountTuple in
            accountTuple.accountPickerAccount.allowSelection && accountTuple.accountPickerAccount.drawerOnSelection == nil
        }
        let firstAccount = [firstSelectableAccount].compactMap({ $0.self })
        dataSource.updateSelectedAccounts(firstAccount)
    }

    private func didSelectConnectAccounts() {
        let nextPane: FinancialConnectionsSessionManifest.NextPane? = {
            if let mostRecentlySelectedAccount = dataSource.selectedAccounts.last {
                return mostRecentlySelectedAccount.partnerAccount.nextPaneOnSelection
            } else {
                return nil
            }
        }()
        guard let nextPane = nextPane else {
            dataSource
                .analyticsClient
                .logUnexpectedError(
                    FinancialConnectionsSheetError
                        .unknown(
                            debugDescription: "Selected connect account, but next pane is NULL."
                        ),
                    errorName: "ConnectUnselectedAccountError",
                    pane: .linkAccountPicker
                )
            // instead of having the user be stuck, we forward them to pick a bank instead
            delegate?.linkAccountPickerViewController(
                self,
                didRequestNextPane: .institutionPicker,
                hideBackButtonOnNextPane: false
            )
            return
        }

        let selectedPartnerAccounts = dataSource.selectedAccounts.map({ $0.partnerAccount })

        // update data model with selected accounts
        delegate?.linkAccountPickerViewController(
            self,
            didSelectAccounts: selectedPartnerAccounts
        )

        self.delegate?.linkAccountPickerViewController(
            self,
            didReceiveEvent: FinancialConnectionsEvent(name: .accountsSelected)
        )

        dataSource
            .analyticsClient
            .log(
                eventName: "click.link_accounts",
                pane: .linkAccountPicker
            )

        dataSource
            .analyticsClient
            .log(
                eventName: "account_picker.accounts_submitted",
                parameters: [
                    "account_ids": selectedPartnerAccounts.map({ $0.id })
                ],
                pane: .linkAccountPicker
            )

        if
            dataSource.acquireConsentOnPrimaryCtaClick,
            let selectedAccount = dataSource.selectedAccounts.first(
                // to better handle multi-select, we want to ensure that
                // the account we pick has a `drawerOnSelection`
                where: { $0.accountPickerAccount.drawerOnSelection != nil }
            ),
            let drawerOnSelection = selectedAccount.accountPickerAccount.drawerOnSelection,
            IsAccountUpdateRequired(forAccount: selectedAccount.partnerAccount)
        {
            footerView?.showLoadingView(true)
            dataSource
                .markConsentAcquired()
                .observe { [weak self] result in
                    guard let self = self else { return }
                    footerView?.showLoadingView(false)
                    switch result {
                    case .success:
                        let coreAuthorization = selectedAccount.partnerAccount.authorization.flatMap {
                            self.dataSource.partnerToCoreAuths?[$0]
                        }
                        self.presentAccountUpdateRequiredDrawer(
                            drawerOnSelection: drawerOnSelection,
                            partnerAccount: selectedAccount.partnerAccount,
                            coreAuthorization: coreAuthorization
                        )
                    case .failure(let error):
                        self.dataSource.analyticsClient.logUnexpectedError(
                            error,
                            errorName: "ConsentAcquiredError",
                            pane: .linkAccountPicker
                        )
                        self.delegate?.linkAccountPickerViewController(self, didReceiveTerminalError: error)
                    }
                }
        } else if nextPane == .success {
            footerView?.showLoadingView(true)
            // prevent user from accidentally pressing
            // a button on the screen; this is safe because
            // next step will transition away from this screen
            view.isUserInteractionEnabled = false

            dataSource
                .selectNetworkedAccounts(selectedPartnerAccounts)
                .observe { [weak self] result in
                    guard let self = self else { return }
                    switch result {
                    case .success(let response):
                        let nextPane = response.nextPane ?? .success
                        if let successPane = response.displayText?.text?.succcessPane {
                            self.delegate?.linkAccountPickerViewController(
                                self,
                                didRequestNextPane: nextPane,
                                customSuccessPaneCaption: successPane.caption,
                                customSuccessPaneSubCaption: successPane.subCaption
                            )
                        } else {
                            self.delegate?.linkAccountPickerViewController(
                                self,
                                didRequestNextPane: nextPane,
                                hideBackButtonOnNextPane: false
                            )
                        }
                    case .failure(let error):
                        self.dataSource
                            .analyticsClient
                            .logUnexpectedError(
                                error,
                                errorName: "SelectNetworkedAccountError",
                                pane: .linkAccountPicker
                            )
                        self.delegate?.linkAccountPickerViewController(self, didReceiveTerminalError: error)
                    }
                }
        } else {

            let pushToNextPane = { [weak self] in
                guard let self = self else { return }
                // we should never push here to these panes here since we will present
                // as sheet when the user selects an account that needs to be repaired
                // or requires additional permissions (supportability)
                if nextPane == .partnerAuth {
                    dataSource
                        .analyticsClient
                        .logUnexpectedError(
                            FinancialConnectionsSheetError
                                .unknown(
                                    debugDescription: "Connecting a supportability account, but user shouldn't be able to."
                                ),
                            errorName: "ConnectSupportabilityAccountError",
                            pane: .linkAccountPicker
                        )
                    delegate?.linkAccountPickerViewController(
                        self,
                        didRequestNextPane: .institutionPicker,
                        hideBackButtonOnNextPane: false
                    )
                } else if nextPane == .bankAuthRepair {
                    dataSource
                        .analyticsClient
                        .logUnexpectedError(
                            FinancialConnectionsSheetError
                                .unknown(
                                    debugDescription: "Connecting a repair account, but user shouldn't be able to."
                                ),
                            errorName: "ConnectRepairAccountError",
                            pane: .linkAccountPicker
                        )
                    delegate?.linkAccountPickerViewController(
                        self,
                        didRequestNextPane: .institutionPicker,
                        hideBackButtonOnNextPane: false
                    )
                } else {
                    // non-sheet next pane -- likely step up
                    delegate?.linkAccountPickerViewController(
                        self,
                        didRequestNextPane: nextPane,
                        hideBackButtonOnNextPane: false
                    )
                }
            }

            if dataSource.acquireConsentOnPrimaryCtaClick {
                footerView?.showLoadingView(true)
                dataSource
                    .markConsentAcquired()
                    .observe { [weak self] result in
                        guard let self = self else { return }
                        footerView?.showLoadingView(false)
                        switch result {
                        case .success:
                            pushToNextPane()
                        case .failure(let error):
                            self.dataSource.analyticsClient.logUnexpectedError(
                                error,
                                errorName: "ConsentAcquiredError",
                                pane: .linkAccountPicker
                            )
                            self.delegate?.linkAccountPickerViewController(self, didReceiveTerminalError: error)
                        }

                    }
            } else {
                pushToNextPane()
            }
        }
    }

    // the "account update required drawer" offers the user two choices:
    // 1. re-link bank account by going through the bank auth flow again (partner_auth pane)
    // 2. repair the bank account (bank_auth_repair)
    private func presentAccountUpdateRequiredDrawer(
        drawerOnSelection: FinancialConnectionsGenericInfoScreen,
        partnerAccount: FinancialConnectionsPartnerAccount,
        coreAuthorization: String?
    ) {
        let deselectPreviouslySelectedAccount = { [weak self] in
            guard let self = self else { return }
            self.dataSource.updateSelectedAccounts(
                self.dataSource.selectedAccounts.filter(
                    { $0.partnerAccount.id != partnerAccount.id }
                )
            )
        }

        var delayDeselectingAccounts = false
        let willDismissSheet = {
            if delayDeselectingAccounts {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    deselectPreviouslySelectedAccount()
                }
            } else {
                deselectPreviouslySelectedAccount()
            }
        }

        let didSelectContinue: () -> Void = { [weak self] in
            guard let self else { return }
            if partnerAccount.nextPaneOnSelection == .partnerAuth {
                if let institution = partnerAccount.institution {
                    self.delegate?.linkAccountPickerViewController(
                        self,
                        requestedPartnerAuthWithInstitution: institution
                    )
                } else {
                    self.delegate?.linkAccountPickerViewController(
                        self,
                        didRequestNextPane: .institutionPicker,
                        hideBackButtonOnNextPane: false
                    )
                }
            } else {
                // nextPaneOnSelection == bankAuthRepair
                if let institution = partnerAccount.institution, let coreAuthorization {
                    self.delegate?.linkAccountPickerViewController(
                        self,
                        requestedBankAuthRepairWithInstitution: institution,
                        forAuthorization: coreAuthorization
                    )
                } else {
                    self.delegate?.linkAccountPickerViewController(
                        self,
                        didRequestNextPane: .institutionPicker,
                        hideBackButtonOnNextPane: false
                    )
                }
            }
        }

        let genericInfoViewController = GenericInfoViewController(
            genericInfoScreen: drawerOnSelection,
            appearance: dataSource.manifest.appearance,
            panePresentationStyle: .sheet,
            iconView: {
                if let institutionIconUrl = partnerAccount.institution?.icon?.default {
                    let institutionIconView = InstitutionIconView()
                    institutionIconView.setImageUrl(institutionIconUrl)
                    return institutionIconView
                } else {
                    return nil
                }
            }(),
            // "did select continue"
            didSelectPrimaryButton: { genericInfoViewController in
                // delay deselecting accounts while we animate to the
                // next screen to reduce "animation jank" of
                // the account getting deselected
                delayDeselectingAccounts = true
                genericInfoViewController.dismiss(
                    animated: true,
                    completion: {
                        didSelectContinue()
                    }
                )
            },
            // "did select cancel"
            didSelectSecondaryButton: { genericInfoViewController in
                delayDeselectingAccounts = false
                genericInfoViewController.dismiss(
                    animated: true
                )
            },
            didSelectURL: { [weak self] url in
                guard let self = self else { return }
                self.didSelectURLInTextFromBackend(url)
            },
            willDismissSheet: willDismissSheet
        )
        genericInfoViewController.present(on: self)
    }

    private func didSelectURLInTextFromBackend(_ url: URL) {
        AuthFlowHelpers.handleURLInTextFromBackend(
            url: url,
            pane: .linkAccountPicker,
            analyticsClient: self.dataSource.analyticsClient,
            handleURL: { _, _ in }
        )
    }
}

// MARK: - LinkAccountPickerBodyViewDelegate

extension LinkAccountPickerViewController: LinkAccountPickerBodyViewDelegate {
    func linkAccountPickerBodyView(
        _ view: LinkAccountPickerBodyView,
        didSelectAccount selectedAccountTuple: FinancialConnectionsAccountTuple
    ) {
        FeedbackGeneratorAdapter.selectionChanged()

        let selectedPartnerAccount = selectedAccountTuple.partnerAccount
        let eligibleToPresentAccountUpdateRequiredDrawer = IsAccountUpdateRequired(
            forAccount: selectedPartnerAccount
        )

        if let drawerOnSelection = selectedAccountTuple.accountPickerAccount.drawerOnSelection {
            // we need the `eligibleToPresentAccountUpdateRequiredDrawer` check here because
            // of confusing evolution of code...`drawerOnSelection` is used for two different
            // types of drawers, so we check `eligibleToPresentAccountUpdateRequiredDrawer`
            // to avoid presenting a drawer here because we will present another drawer later
            if !eligibleToPresentAccountUpdateRequiredDrawer {
                // the "account selection drawer" gives user an explanation of
                // why they can't use this bank account
                let accountSelectionDrawerViewController = GenericInfoViewController(
                    genericInfoScreen: drawerOnSelection,
                    appearance: dataSource.manifest.appearance,
                    panePresentationStyle: .sheet,
                    didSelectPrimaryButton: { genericInfoViewController in
                        genericInfoViewController.dismiss(animated: true)
                    },
                    didSelectURL: { [weak self] url in
                        guard let self = self else { return }
                        self.didSelectURLInTextFromBackend(url)
                    }
                )
                accountSelectionDrawerViewController.present(on: self)
            } else {
                // we will (likely) be presenting a different drawer further down the function
            }

            // this extra `allowSelection` check is necessary because we override
            // `isDisabled` for `AccountPickerRowView` when `drawerOnSelection != nil`
            if !selectedAccountTuple.accountPickerAccount.allowSelection {
                // if the account is not selectable, then we return early
                return
            }
        }

        // unselecting
        if
            // unselecting in single account flow is not allowed
            !dataSource.manifest.singleAccount,
            // unselect if the account is already selected
            dataSource.selectedAccounts.contains(
                where: { $0.partnerAccount.id == selectedPartnerAccount.id }
            )
        {
            dataSource
                .analyticsClient
                .log(
                    eventName: "click.account_picker.account_unselected",
                    parameters: [
                        "account": selectedPartnerAccount.id,
                        "is_single_account": dataSource.manifest.singleAccount,
                    ],
                    pane: .linkAccountPicker
                )

            dataSource.updateSelectedAccounts(
                dataSource.selectedAccounts.filter(
                    { $0.partnerAccount.id != selectedPartnerAccount.id }
                )
            )
        }
        // selecting
        else {
            dataSource
                .analyticsClient
                .log(
                    eventName: "click.account_picker.account_selected",
                    parameters: [
                        "account": selectedPartnerAccount.id,
                        "is_single_account": dataSource.manifest.singleAccount,
                    ],
                    pane: .linkAccountPicker
                )

            if dataSource.manifest.singleAccount {
                dataSource.updateSelectedAccounts([selectedAccountTuple])
            }
            // multi-select
            else {
                dataSource.updateSelectedAccounts(
                    dataSource.selectedAccounts + [selectedAccountTuple]
                )
            }

            // some values for nextPane require immediate action (ie. popping up a sheet for repair)
            // as opposed to pushing the next pane upon CTA click (ie. step-up verification)
            if eligibleToPresentAccountUpdateRequiredDrawer {
                if let drawerOnSelection = selectedAccountTuple.accountPickerAccount.drawerOnSelection {
                    if selectedPartnerAccount.nextPaneOnSelection == .bankAuthRepair {
                        dataSource
                            .analyticsClient
                            .log(
                                eventName: "click.repair_accounts",
                                pane: .linkAccountPicker
                            )
                    } else {
                        dataSource
                            .analyticsClient
                            .log(
                                eventName: "click.supportability_account",
                                pane: .linkAccountPicker
                            )
                    }

                    // if we need to acquire consent, instead of showing the drawer now,
                    // we will show the drawer when user presses the CTA where
                    // pressing the CTA will make a call to `markConsentAcquired`
                    if !dataSource.acquireConsentOnPrimaryCtaClick {
                        let coreAuthorization = selectedPartnerAccount.authorization.flatMap {
                            dataSource.partnerToCoreAuths?[$0]
                        }
                        presentAccountUpdateRequiredDrawer(
                            drawerOnSelection: drawerOnSelection,
                            partnerAccount: selectedPartnerAccount,
                            coreAuthorization: coreAuthorization
                        )
                    }
                } else {
                    dataSource
                        .analyticsClient
                        .logUnexpectedError(
                            FinancialConnectionsSheetError.unknown(
                                debugDescription: "User was eligible for AccountUpdateRequiredDrawer but backend didn't return drawerOnSelection"
                            ),
                            errorName: "CantPresentAccountUpdateRequiredDrawer",
                            pane: .linkAccountPicker
                        )
                }
            }
        }
    }

    func linkAccountPickerBodyViewSelectedNewBankAccount(_ view: LinkAccountPickerBodyView) {
        FeedbackGeneratorAdapter.buttonTapped()
        dataSource
            .analyticsClient
            .log(
                eventName: "click.new_account",
                pane: .linkAccountPicker
            )
        delegate?.linkAccountPickerViewController(
            self,
            didRequestNextPane: dataSource.nextPaneOnAddAccount ?? .institutionPicker,
            hideBackButtonOnNextPane: false
        )
    }
}

// MARK: - LinkAccountPickerDataSourceDelegate

extension LinkAccountPickerViewController: LinkAccountPickerDataSourceDelegate {

    func linkAccountPickerDataSource(
        _ dataSource: LinkAccountPickerDataSource,
        didSelectAccounts selectedAccounts: [FinancialConnectionsAccountTuple]
    ) {
        bodyView?.selectAccounts(selectedAccounts)
        footerView?.didSelectAccounts(selectedAccounts)
    }
}

/// Combines two different `account` types into one type
typealias FinancialConnectionsAccountTuple = (
    accountPickerAccount: FinancialConnectionsNetworkingAccountPicker.Account,
    partnerAccount: FinancialConnectionsPartnerAccount
)
private func ZipAccounts(
    partnerAccounts: [FinancialConnectionsPartnerAccount],
    accountPickerAccounts: [FinancialConnectionsNetworkingAccountPicker.Account]
) -> [FinancialConnectionsAccountTuple] {
    var accountTuples: [FinancialConnectionsAccountTuple] = []
    let idToPartnerAccount = Dictionary(uniqueKeysWithValues: partnerAccounts.map({ ($0.id, $0) }))
    // use `accountPickerAccounts` to determine the order as its
    // used for defining how we display the account
    for accountPickerAccount in accountPickerAccounts {
        if let partnerAccount = idToPartnerAccount[accountPickerAccount.id] {
            accountTuples.append((accountPickerAccount, partnerAccount))
        }
    }
    return accountTuples
}

private func IsAccountUpdateRequired(
    forAccount account: FinancialConnectionsPartnerAccount
) -> Bool {
    // repair flow
    return account.nextPaneOnSelection == .bankAuthRepair
    // supportability -- account requires re-sharing with additonal permissions
    || account.nextPaneOnSelection == .partnerAuth
    || account.nextPaneOnSelection == .institutionPicker
}
