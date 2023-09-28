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
    private let sharedPartnerAuthViewController: SharedPartnerAuthViewController
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
        self.sharedPartnerAuthViewController = SharedPartnerAuthViewController(
            dataSource: dataSource.sharedPartnerAuthDataSource
        )
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .customBackgroundColor

        addChild(sharedPartnerAuthViewController)
        view.addAndPinSubview(sharedPartnerAuthViewController.view)
        sharedPartnerAuthViewController.didMove(toParent: self)

        dataSource
            .analyticsClient
            .logPaneLoaded(pane: .bankAuthRepair)

        sharedPartnerAuthViewController.showConnectingToBankView(true)
        dataSource
            .initiateAuthRepairSession()
            .observe(on: .main) { [weak self] result in
                guard let self = self else { return }
                sharedPartnerAuthViewController.showConnectingToBankView(false)

                switch result {
                case .success(let authRepairSession):
                    self.sharedPartnerAuthViewController.startWithAuthSession(
                        FinancialConnectionsAuthSession(
                            id: authRepairSession.id,
                            flow: authRepairSession.flow,
                            institutionSkipAccountSelection: nil,
                            nextPane: .success,
                            showPartnerDisclosure: nil,
                            skipAccountSelection: nil,
                            url: authRepairSession.url,
                            isOauth: authRepairSession.isOauth,
                            display: authRepairSession.display
                        )
                    )
                case .failure(let error):
                    self.dataSource
                        .analyticsClient
                        .logUnexpectedError(
                            error,
                            errorName: "InitiateAuthRepairSessionError",
                            pane: .bankAuthRepair
                        )
                    // TODO(kgaidis): 2. go back to link account picker...
                }
            }
    }

    private func repairSessionCompleted() {
//        if (multiAccountFlow) {
//          pushPane('link_account_picker');
//        } else {
//          shareNetworkedAccounts();
//        }

    }
}

// MARK: - SharedPartnerAuthViewControllerDelegate

extension BankAuthRepairViewController: SharedPartnerAuthViewControllerDelegate {

    func sharedPartnerAuthViewController(
        _ viewController: SharedPartnerAuthViewController,
        didSucceedWithAuthSession authSession: FinancialConnectionsAuthSession,
        considerCallingAuthorize: Bool
    ) {
        print(authSession)

        if authSession.isOauthNonOptional {
            dataSource.completeAuthRepairSession(
                authRepairSessionId: authSession.id
            )
            .observe(on: .main) { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success(let authRepairSessionComplete):
                    print(authRepairSessionComplete)
                    self.repairSessionCompleted()
                case .failure(let error):
                    print(error)
                }
            }
        } else {
            repairSessionCompleted()
        }
    }

    func sharedPartnerAuthViewController(
        _ viewController: SharedPartnerAuthViewController,
        didCancelWithAuthSession authSession: FinancialConnectionsAuthSession,
        statusWasReturned: Bool
    ) {
        print(authSession)
    }

    func sharedPartnerAuthViewController(
        _ viewController: SharedPartnerAuthViewController,
        didFailWithAuthSession authSession: FinancialConnectionsAuthSession
    ) {
        print(authSession)
    }

    func sharedPartnerAuthViewControllerDidRequestToGoBack(
        _ viewController: SharedPartnerAuthViewController
    ) {
        print("sharedPartnerAuthViewControllerDidRequestToGoBack")
    }

    func sharedPartnerAuthViewController(
        _ viewController: SharedPartnerAuthViewController,
        didReceiveError error: Error
    ) {
        print(error)
    }

    func sharedPartnerAuthViewController(
        _ viewController: SharedPartnerAuthViewController,
        didReceiveTerminalError error: Error
    ) {
        print(error)
    }
}
