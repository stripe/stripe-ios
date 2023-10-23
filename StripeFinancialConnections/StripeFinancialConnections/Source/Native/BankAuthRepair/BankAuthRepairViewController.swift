//
//  BankAuthRepairViewController.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 9/26/23.
//

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

    private let dataSource: BankAuthRepairDataSource
    private let sharedPartnerAuthViewController: SharedPartnerAuthViewController
    weak var delegate: BankAuthRepairViewControllerDelegate?

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
}
