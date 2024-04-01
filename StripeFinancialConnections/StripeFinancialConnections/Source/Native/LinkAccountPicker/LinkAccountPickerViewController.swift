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
        didRequestNextPane nextPane: FinancialConnectionsSessionManifest.NextPane
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
    private weak var lastAccountUpdateRequiredViewController: UIViewController?

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
        view.backgroundColor = .customBackgroundColor

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
                    if let returningNetworkingUserAccountPicker = networkedAccountsResponse.display?.text?.returningNetworkingUserAccountPicker {
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
                    self.delegate?.linkAccountPickerViewController(self, didRequestNextPane: .institutionPicker)
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
            addNewAccount: networkingAccountPicker.addNewAccount
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
            isStripeDirect: false,
            businessName: businessName,
            permissions: dataSource.manifest.permissions,
            singleAccount: dataSource.manifest.singleAccount,
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
                        didSelectUrl: { [weak self] url in
                            guard let self = self else { return }
                            AuthFlowHelpers.handleURLInTextFromBackend(
                                url: url,
                                pane: .linkAccountPicker,
                                analyticsClient: self.dataSource.analyticsClient,
                                handleStripeScheme: { _ in }
                            )
                        }
                    )
                    dataAccessNoticeViewController.present(on: self)
                }
            }
        )
        self.footerView = footerView
        footerContainerView.addAndPinSubview(footerView)

        bodyView.selectAccounts([]) // activate the logic to list all accounts
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
                didRequestNextPane: .institutionPicker
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

        if nextPane == .success {
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
                    case .success:
                        self.delegate?.linkAccountPickerViewController(
                            self,
                            didRequestNextPane: .success
                        )
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
            // we should never push here to these panes since we will present
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
                    didRequestNextPane: .institutionPicker
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
                    didRequestNextPane: .institutionPicker
                )
            } else {
                // non-sheet next pane -- likely step up
                delegate?.linkAccountPickerViewController(self, didRequestNextPane: nextPane)
            }
        }
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
            if
                // repair flow
                selectedPartnerAccount.nextPaneOnSelection == .bankAuthRepair
                    // supportability -- account requires re-sharing with additonal permissions
                    || selectedPartnerAccount.nextPaneOnSelection == .partnerAuth
            {
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

                let deselectPreviouslySelectedAccount = { [weak self] in
                    guard let self = self else { return }
                    self.dataSource.updateSelectedAccounts(
                        self.dataSource.selectedAccounts.filter(
                            { $0.partnerAccount.id != selectedPartnerAccount.id }
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
                    if selectedPartnerAccount.nextPaneOnSelection == .partnerAuth {
                        if let institution = selectedPartnerAccount.institution {
                            self.delegate?.linkAccountPickerViewController(
                                self,
                                requestedPartnerAuthWithInstitution: institution
                            )
                        } else {
                            self.delegate?.linkAccountPickerViewController(
                                self,
                                didRequestNextPane: .institutionPicker
                            )
                        }
                    }
                    // nextPaneOnSelection == bankAuthRepair
                    else {
                        dataSource
                            .analyticsClient
                            .logUnexpectedError(
                                FinancialConnectionsSheetError
                                    .unknown(
                                        debugDescription: "Updating a repair account, but repairs are not supported in Mobile."
                                    ),
                                errorName: "UpdateRepairAccountError",
                                pane: .linkAccountPicker
                            )
                        delegate?.linkAccountPickerViewController(
                            self,
                            didRequestNextPane: .institutionPicker
                        )
                    }
                }

                let accountUpdateRequiredViewController = AccountUpdateRequiredViewController(
                    institution: selectedPartnerAccount.institution,
                    didSelectContinue: { [weak self] in
                        guard let self else { return }
                        // delay deselecting accounts while we animate to the
                        // next screen to reduce "animation jank" of
                        // the account getting deselected
                        delayDeselectingAccounts = true
                        self.lastAccountUpdateRequiredViewController?.dismiss(
                            animated: true,
                            completion: {
                                didSelectContinue()
                            }
                        )
                    },
                    didSelectCancel: { [weak self] in
                        delayDeselectingAccounts = false
                        self?.lastAccountUpdateRequiredViewController?.dismiss(
                            animated: true
                        )
                    },
                    willDismissSheet: willDismissSheet
                )
                lastAccountUpdateRequiredViewController = accountUpdateRequiredViewController
                accountUpdateRequiredViewController.present(on: self)
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
            didRequestNextPane: dataSource.nextPaneOnAddAccount ?? .institutionPicker
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
