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
    func bankAuthRepairViewController(
        _ viewController: BankAuthRepairViewController,
        didSucceedWithInstitution institution: FinancialConnectionsInstitution?
    )
    func bankAuthRepairViewControllerDidRequestToGoBackToLinkAccountPicker(
        _ viewController: BankAuthRepairViewController
    )
    func bankAuthRepairViewController(
        _ viewController: BankAuthRepairViewController,
        didReceiveTerminalError error: Error
    )
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
        sharedPartnerAuthViewController.delegate = self
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
                    self.delegate?.bankAuthRepairViewControllerDidRequestToGoBackToLinkAccountPicker(self)
                }
            }
    }

    private func repairSessionCompleted() {
        dataSource
            .selectNetworkedAccount()
            .observe(on: .main) { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success(let response):
                    self.delegate?.bankAuthRepairViewController(
                        self,
                        didSucceedWithInstitution: response.data.first
                    )
                case .failure(let error):
                    self.delegate?.bankAuthRepairViewController(
                        self,
                        didReceiveTerminalError: error
                    )
                }
            }
    }
}

// MARK: - SharedPartnerAuthViewControllerDelegate

extension BankAuthRepairViewController: SharedPartnerAuthViewControllerDelegate {

    func sharedPartnerAuthViewController(
        _ viewController: SharedPartnerAuthViewController,
        didSucceedWithAuthSession authSession: FinancialConnectionsAuthSession,
        considerCallingAuthorize: Bool
    ) {
        if authSession.isOauthNonOptional {
            dataSource.completeAuthRepairSession(
                authRepairSessionId: authSession.id
            )
            .observe(on: .main) { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success:
                    self.repairSessionCompleted()
                case .failure(let error):
                    self.delegate?.bankAuthRepairViewController(self, didReceiveTerminalError: error)
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
        delegate?.bankAuthRepairViewControllerDidRequestToGoBackToLinkAccountPicker(self)
    }

    func sharedPartnerAuthViewController(
        _ viewController: SharedPartnerAuthViewController,
        didFailWithAuthSession authSession: FinancialConnectionsAuthSession
    ) {
        delegate?.bankAuthRepairViewControllerDidRequestToGoBackToLinkAccountPicker(self)
    }

    func sharedPartnerAuthViewControllerDidRequestToGoBack(
        _ viewController: SharedPartnerAuthViewController
    ) {
        delegate?.bankAuthRepairViewControllerDidRequestToGoBackToLinkAccountPicker(self)
    }

    func sharedPartnerAuthViewController(
        _ viewController: SharedPartnerAuthViewController,
        didReceiveError error: Error
    ) {
        delegate?.bankAuthRepairViewControllerDidRequestToGoBackToLinkAccountPicker(self)
    }

    func sharedPartnerAuthViewController(
        _ viewController: SharedPartnerAuthViewController,
        didReceiveTerminalError error: Error
    ) {
        delegate?.bankAuthRepairViewController(self, didReceiveTerminalError: error)
    }
}
