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

@available(iOSApplicationExtension, unavailable)
protocol LinkAccountPickerViewControllerDelegate: AnyObject {
    func linkAccountPickerViewController(
        _ viewController: LinkAccountPickerViewController,
        didRequestNextPane nextPane: FinancialConnectionsSessionManifest.NextPane
    )

    func linkAccountPickerViewController(
        _ viewController: LinkAccountPickerViewController,
        didSelectAccount selectedAccount: FinancialConnectionsPartnerAccount,
        institution: FinancialConnectionsInstitution
    )

    func linkAccountPickerViewController(
        _ viewController: LinkAccountPickerViewController,
        requestedStepUpVerificationWithSelectedAccount selectedAccount: FinancialConnectionsPartnerAccount
    )

    func linkAccountPickerViewController(
        _ viewController: LinkAccountPickerViewController,
        didReceiveTerminalError error: Error
    )
}

@available(iOSApplicationExtension, unavailable)
final class LinkAccountPickerViewController: UIViewController {

    private let dataSource: LinkAccountPickerDataSource
    weak var delegate: LinkAccountPickerViewControllerDelegate?
    private var businessName: String? {
        return dataSource.manifest.businessName
    }
    private weak var bodyView: LinkAccountPickerBodyView?
    private lazy var footerView: LinkAccountPickerFooterView = {
        return LinkAccountPickerFooterView(
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
    }()

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
                    self.displayAccounts(networkedAccountsResponse.data)
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

    private func displayAccounts(_ accounts: [FinancialConnectionsPartnerAccount]) {
        let bodyView = LinkAccountPickerBodyView(accounts: accounts)
        bodyView.delegate = self
        self.bodyView = bodyView

        let paneLayoutView = PaneWithHeaderLayoutView(
            title: {
                if let businessName = self.businessName {
                    return String(
                        format: STPLocalizedString(
                            "Select an account to connect to %@",
                            "The title of a screen that allows users to select which bank accounts they want to use to pay for something."
                        ),
                        businessName
                    )
                } else {
                    return STPLocalizedString(
                        "Select an account to connect with this business",
                        "The title of a screen that allows users to select which bank accounts they want to use to pay for something."
                    )
                }
            }(),
            contentView: bodyView,
            footerView: footerView
        )
        paneLayoutView.addTo(view: view)

        bodyView.selectAccount(nil) // activate the logic to list all accounts
    }

    private func didSelectConectAccount() {
        // TODO(kgaidis): implement repair bank account

        guard let selectedAccount = dataSource.selectedAccount else {
            assertionFailure("user shouldn't be able to press the connect account button without an account")
            delegate?.linkAccountPickerViewController(self, didRequestNextPane: .institutionPicker)
            return
        }

        if dataSource.manifest.stepUpAuthenticationRequired == true {
            delegate?.linkAccountPickerViewController(self, requestedStepUpVerificationWithSelectedAccount: selectedAccount)
        } else {
            let linkingAccountsLoadingView = LinkingAccountsLoadingView(
                numberOfSelectedAccounts: 1,
                businessName: businessName
            )
            view.addAndPinSubviewToSafeArea(linkingAccountsLoadingView)

            dataSource
                .selectNetworkedAccount(selectedAccount)
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
                            self.delegate?.linkAccountPickerViewController(self, didSelectAccount: selectedAccount, institution: institution)
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
        }
    }
}

// MARK: - LinkAccountPickerBodyViewDelegate

@available(iOSApplicationExtension, unavailable)
extension LinkAccountPickerViewController: LinkAccountPickerBodyViewDelegate {
    func linkAccountPickerBodyView(
        _ view: LinkAccountPickerBodyView,
        didSelectAccount selectedAccount: FinancialConnectionsPartnerAccount
    ) {
        dataSource.updateSelectedAccount(selectedAccount)
    }

    func linkAccountPickerBodyViewSelectedNewBankAccount(_ view: LinkAccountPickerBodyView) {
        dataSource
            .analyticsClient
            .log(
                eventName: "click.new_account",
                pane: .linkAccountPicker
            )
        delegate?.linkAccountPickerViewController(self, didRequestNextPane: .institutionPicker)
    }
}

// MARK: - LinkAccountPickerDataSourceDelegate

@available(iOSApplicationExtension, unavailable)
extension LinkAccountPickerViewController: LinkAccountPickerDataSourceDelegate {

    func linkAccountPickerDataSource(
        _ dataSource: LinkAccountPickerDataSource,
        didSelectAccount selectedAccount: FinancialConnectionsPartnerAccount?
    ) {
        bodyView?.selectAccount(selectedAccount)
        footerView.enableButton(selectedAccount != nil)
    }
}
