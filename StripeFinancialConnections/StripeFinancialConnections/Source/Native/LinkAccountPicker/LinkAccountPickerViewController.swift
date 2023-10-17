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
        didSelectAccount selectedAccount: FinancialConnectionsPartnerAccount
    )

    func linkAccountPickerViewController(
        _ viewController: LinkAccountPickerViewController,
        didRequestSuccessPaneWithInstitution institution: FinancialConnectionsInstitution
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
        view.backgroundColor = .customBackgroundColor

        fetchNetworkedAccounts()
    }

    private func fetchNetworkedAccounts() {
        let retreivingAccountsLoadingView = buildRetrievingAccountsView()
        view.addAndPinSubviewToSafeArea(retreivingAccountsLoadingView)
        dataSource
            .fetchNetworkedAccounts()
            .observe { [weak self] result in
                guard let self = self else { return }
                retreivingAccountsLoadingView.removeFromSuperview()
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
                self.didSelectConectAccount()
            },
            didSelectMerchantDataAccessLearnMore: { [weak self] in
                guard let self = self else { return }
                self.dataSource
                    .analyticsClient
                    .logMerchantDataAccessLearnMore(pane: .linkAccountPicker)
            }
        )
        self.footerView = footerView

        let paneLayoutView = PaneWithHeaderLayoutView(
            title: networkingAccountPicker.title,
            contentView: bodyView,
            footerView: footerView
        )
        paneLayoutView.addTo(view: view)

        bodyView.selectAccount(nil) // activate the logic to list all accounts
    }

    private func didSelectConectAccount() {
        guard let selectedAccountTuple = dataSource.selectedAccountTuple else {
            assertionFailure("user shouldn't be able to press the connect account button without an account")
            dataSource
                .analyticsClient
                .logUnexpectedError(
                    FinancialConnectionsSheetError
                        .unknown(
                            debugDescription: "Selected to connect an account, but no account is selected."
                        ),
                    errorName: "ConnectUnselectedAccountError",
                    pane: .linkAccountPicker
                )
            delegate?.linkAccountPickerViewController(self, didRequestNextPane: .institutionPicker)
            return
        }

        let nextPane = selectedAccountTuple
            .partnerAccount
            .nextPaneOnSelection

        // update data model with selected account
        delegate?.linkAccountPickerViewController(
            self,
            didSelectAccount: selectedAccountTuple.partnerAccount
        )

        self.delegate?.linkAccountPickerViewController(
            self,
            didReceiveEvent: FinancialConnectionsEvent(name: .accountsSelected)
        )

        if nextPane == .success {
            let linkingAccountsLoadingView = LinkingAccountsLoadingView(
                numberOfSelectedAccounts: 1,
                businessName: businessName
            )
            view.addAndPinSubviewToSafeArea(linkingAccountsLoadingView)

            dataSource
                .selectNetworkedAccount(selectedAccountTuple.partnerAccount)
                .observe { [weak self] result in
                    guard let self = self else { return }
                    switch result {
                    case .success(let institutionList):
                        self.dataSource
                            .analyticsClient
                            .log(
                                eventName: "click.link_accounts",
                                pane: .linkAccountPicker
                            )

                        if let institution = institutionList.data.first {
                            self.delegate?.linkAccountPickerViewController(
                                self,
                                didRequestSuccessPaneWithInstitution: institution
                            )
                        } else {
                            // this should never happen, but in case it does we want to force a
                            // a terminal error so user can start again with a fresh state
                            let error = FinancialConnectionsSheetError.unknown(
                                debugDescription: "Successfully selected an networked account but no institution was returned."
                            )
                            self.dataSource
                                .analyticsClient
                                .logUnexpectedError(
                                    error,
                                    errorName: "SelectNetworkedAccountNoInstitutionError",
                                    pane: .linkAccountPicker
                                )
                            self.delegate?.linkAccountPickerViewController(
                                self,
                                didReceiveTerminalError: error
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
        } else if nextPane == .partnerAuth {
            if let institution = selectedAccountTuple.partnerAccount.institution {
                delegate?.linkAccountPickerViewController(
                    self,
                    requestedPartnerAuthWithInstitution: institution
                )
            } else {
                delegate?.linkAccountPickerViewController(
                    self,
                    didReceiveTerminalError: FinancialConnectionsSheetError.unknown(
                        debugDescription: "LinkAccountPicker wanted to go to partner_auth but there is no institution."
                    )
                )
            }
        } else if let nextPane = nextPane {
            if nextPane == .bankAuthRepair {
                dataSource
                    .analyticsClient
                    .log(
                        eventName: "click.repair_accounts",
                        pane: .linkAccountPicker
                    )
            }
            delegate?.linkAccountPickerViewController(self, didRequestNextPane: nextPane)
        } else {
            delegate?.linkAccountPickerViewController(
                self,
                didReceiveTerminalError: FinancialConnectionsSheetError.unknown(
                    debugDescription: "LinkAccountPicker pressed account but no nextPane returned."
                )
            )
        }
    }
}

// MARK: - LinkAccountPickerBodyViewDelegate

extension LinkAccountPickerViewController: LinkAccountPickerBodyViewDelegate {
    func linkAccountPickerBodyView(
        _ view: LinkAccountPickerBodyView,
        didSelectAccount selectedAccountTuple: FinancialConnectionsAccountTuple
    ) {
        dataSource
            .analyticsClient
            .log(
                eventName: "click.account_picker.account_selected",
                parameters: [
                    "account": selectedAccountTuple.partnerAccount.id,
                    "is_single_account": true,
                ],
                pane: .linkAccountPicker
            )
        dataSource.updateSelectedAccount(selectedAccountTuple)
    }

    func linkAccountPickerBodyViewSelectedNewBankAccount(_ view: LinkAccountPickerBodyView) {
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
        didSelectAccount selectedAccountTuple: FinancialConnectionsAccountTuple?
    ) {
        bodyView?.selectAccount(selectedAccountTuple)
        footerView?.didSelectedAccount(selectedAccountTuple)
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
