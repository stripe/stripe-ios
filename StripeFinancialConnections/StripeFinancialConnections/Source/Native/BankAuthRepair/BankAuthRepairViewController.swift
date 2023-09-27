//
//  BankAuthRepairViewController.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 9/26/23.
//

import AuthenticationServices
import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
import UIKit

protocol BankAuthRepairViewControllerDelegate: AnyObject {

}

final class BankAuthRepairViewController: UIViewController {

    /**
     Unfortunately there is a need for this state-full parameter. When we get url callback the app might not be in foreground state.
     If we then authorize the auth session will fail as you can't do background networking without special permission.
     */
    private var unprocessedReturnURL: URL?
    private var subscribedToURLNotifications = false
    private var subscribedToAppActiveNotifications = false
    private var continueStateView: ContinueStateView?

    private let dataSource: BankAuthRepairDataSource
//    private var institution: FinancialConnectionsInstitution {
//        return dataSource.institution
//    }
    private var webAuthenticationSession: ASWebAuthenticationSession?
    private var lastHandledAuthenticationSessionReturnUrl: URL?
    weak var delegate: BankAuthRepairViewControllerDelegate?

    private lazy var establishingConnectionLoadingView: UIView = {
        let establishingConnectionLoadingView = ReusableInformationView(
            iconType: .loading,
            title: STPLocalizedString(
                "Establishing connection",
                "The title of the loading screen that appears after a user selected a bank. The user is waiting for Stripe to establish a bank connection with the bank."
            ),
            subtitle: STPLocalizedString(
                "Please wait while we connect to your bank.",
                "The subtitle of the loading screen that appears after a user selected a bank. The user is waiting for Stripe to establish a bank connection with the bank."
            )
        )
        establishingConnectionLoadingView.isHidden = true
        return establishingConnectionLoadingView
    }()

    private lazy var retrievingAccountsView: UIView = {
        return buildRetrievingAccountsView()
    }()

    init(dataSource: BankAuthRepairDataSource) {
        self.dataSource = dataSource
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .customBackgroundColor
        dataSource
            .analyticsClient
            .logPaneLoaded(pane: .bankAuthRepair)

        dataSource
            .initiateAuthRepairSession()
            .observe(on: .main) { _ in

            }
    }
}
