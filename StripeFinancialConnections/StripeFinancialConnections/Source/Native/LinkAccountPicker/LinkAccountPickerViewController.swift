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
        didSelectAccounts selectedAccounts: [FinancialConnectionsPartnerAccount]
    )
    func linkAccountPickerViewControllerDidSelectAnotherBank(_ viewController: LinkAccountPickerViewController)
    func linkAccountPickerViewControllerDidSelectManualEntry(_ viewController: LinkAccountPickerViewController)
    func linkAccountPickerViewController(
        _ viewController: LinkAccountPickerViewController,
        didReceiveTerminalError error: Error
    )
}

enum LinkAccountPickerType {
    case checkbox
    case radioButton
}

@available(iOSApplicationExtension, unavailable)
final class LinkAccountPickerViewController: UIViewController {

    private let dataSource: LinkAccountPickerDataSource
    weak var delegate: LinkAccountPickerViewControllerDelegate?
    private var businessName: String? {
        return dataSource.manifest.businessName
    }

    private lazy var footerView: LinkAccountPickerFooterView = {
        return LinkAccountPickerFooterView(
            isStripeDirect: dataSource.manifest.isStripeDirect ?? false,
            businessName: businessName,
            permissions: dataSource.manifest.permissions,
            singleAccount: dataSource.manifest.singleAccount,
            didSelectConnectAccount: { [weak self] in
                guard let self = self else {
                    return
                }
                self.dataSource
                    .analyticsClient
                    .log(
                        eventName: "click.link_accounts",
                        parameters: ["pane": FinancialConnectionsSessionManifest.NextPane.linkAccountPicker.rawValue]
                    )

                self.didSelectLinkAccounts()
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
                    print(error)
                    break
                }
            }
    }

    private func displayAccounts(_ accounts: [FinancialConnectionsPartnerAccount]) {
        let paneLayoutView = PaneWithHeaderLayoutView(
            title: {
                if let businessName = self.businessName {
                    // TODO(kgaidis): localize string
                    return "Select an account to connect to \(businessName)"
                } else {
                    return STPLocalizedString(
                        "Select an account to connect with this business",
                        "The title of a screen that allows users to select which bank accounts they want to use to pay for something."
                    )
                }
            }(),
            contentView: UIView(),
            footerView: footerView
        )
        paneLayoutView.addTo(view: view)
    }

    private func didSelectLinkAccounts() {
        let numberOfSelectedAccounts = dataSource.selectedAccounts.count
        let linkingAccountsLoadingView = LinkingAccountsLoadingView(
            numberOfSelectedAccounts: numberOfSelectedAccounts,
            businessName: businessName
        )
        view.addAndPinSubviewToSafeArea(linkingAccountsLoadingView)

//        dataSource
//            .selectAuthSessionAccounts()
//            .observe(on: .main) { [weak self] result in
//                guard let self = self else { return }
//                switch result {
//                case .success(let linkedAccounts):
//                    self.delegate?.linkAccountPickerViewController(
//                        self,
//                        didSelectAccounts: linkedAccounts.data
//                    )
//                case .failure(let error):
//                    self.dataSource
//                        .analyticsClient
//                        .logUnexpectedError(
//                            error,
//                            errorName: "SelectAuthSessionAccountsError",
//                            pane: .linkAccountPicker
//                        )
//                    self.delegate?.linkAccountPickerViewController(self, didReceiveTerminalError: error)
//                }
//            }
    }
}

// MARK: - LinkAccountPickerSelectionViewDelegate

//@available(iOSApplicationExtension, unavailable)
//extension LinkAccountPickerViewController: LinkAccountPickerSelectionViewDelegate {
//
//    func linkAccountPickerSelectionView(
//        _ view: LinkAccountPickerSelectionView,
//        didSelectAccounts selectedAccounts: [FinancialConnectionsPartnerAccount]
//    ) {
//        dataSource.updateSelectedAccounts(selectedAccounts)
//    }
//}

// MARK: - LinkAccountPickerDataSourceDelegate

@available(iOSApplicationExtension, unavailable)
extension LinkAccountPickerViewController: LinkAccountPickerDataSourceDelegate {
    func linkLinkAccountPickerDataSource(
        _ dataSource: LinkAccountPickerDataSource,
        didSelectAccounts selectedAccounts: [FinancialConnectionsPartnerAccount]
    ) {
        footerView.didSelectAccounts(count: selectedAccounts.count)
        // linkAccountPickerSelectionView?.selectAccounts(selectedAccounts)
    }
}
