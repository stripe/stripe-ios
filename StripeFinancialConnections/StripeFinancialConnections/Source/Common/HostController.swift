//
//  HostController.swift
//  StripeFinancialConnections
//
//  Created by Vardges Avetisyan on 6/3/22.
//

import UIKit

protocol HostControllerDelegate: AnyObject {

    func hostController(
        _ hostController: HostController,
        viewController: UIViewController,
        didFinish result: FinancialConnectionsSheet.Result
    )
}

class HostController {
    
    // MARK: - Properties
    
    private let api: FinancialConnectionsAPIClient
    private let clientSecret: String
    private var authFlowController: AuthFlowController?

    lazy var hostViewController = HostViewController(clientSecret: clientSecret, apiClient: api, delegate: self)
    lazy var navigationController = FinancialConnectionsNavigationController(rootViewController: hostViewController)
    
    weak var delegate: HostControllerDelegate?
    
    // Temporary way to control which flow to use
    var useNative = false
    
    // MARK: - Init
    
    init(api: FinancialConnectionsAPIClient,
         clientSecret: String) {
        self.api = api
        self.clientSecret = clientSecret
        navigationController.dismissDelegate = hostViewController
    }
}

// MARK: - HostViewControllerDelegate

extension HostController: HostViewControllerDelegate {
    func hostViewControllerDidFinish(_ viewController: HostViewController, lastError: Error?) {
        guard let error = lastError else {
            delegate?.hostController(self, viewController: viewController, didFinish: .canceled)
            return
        }

        delegate?.hostController(self, viewController: viewController, didFinish: .failed(error: error))
    }

    func hostViewController(_ viewController: HostViewController, didFetch manifest: FinancialConnectionsSessionManifest) {
        guard useNative else {
            continueWithWebFlow(manifest)
            return
        }

        let dataManager = AuthFlowAPIDataManager(with: manifest,
                                                     api: api,
                                                     clientSecret: clientSecret)
        authFlowController = AuthFlowController(dataManager: dataManager, navigationController: navigationController)
        navigationController.dismissDelegate = authFlowController
        authFlowController?.delegate = self
        authFlowController?.startFlow()
    }
}

// MARK: - Helpers

private extension HostController {
 
    func continueWithWebFlow(_ manifest: FinancialConnectionsSessionManifest) {
        let accountFetcher = FinancialConnectionsAccountAPIFetcher(api: api, clientSecret: clientSecret)
        let sessionFetcher = FinancialConnectionsSessionAPIFetcher(api: api, clientSecret: clientSecret, accountFetcher: accountFetcher)
        let webFlowController = FinancialConnectionsWebFlowViewController(clientSecret: clientSecret,
                                                                              apiClient: api,
                                                                              manifest: manifest,
                                                                              sessionFetcher: sessionFetcher)
        webFlowController.delegate = self
        navigationController.dismissDelegate = webFlowController
        navigationController.setViewControllers([webFlowController], animated: true)
    }
}

// MARK: - ConnectionsWebFlowViewControllerDelegate

extension HostController: FinancialConnectionsWebFlowViewControllerDelegate {
    func financialConnectionsWebFlow(viewController: FinancialConnectionsWebFlowViewController, didFinish result: FinancialConnectionsSheet.Result) {
        delegate?.hostController(self, viewController: viewController, didFinish: result)
    }
}

extension HostController: AuthFlowControllerDelegate {
    func authFlow(controller: AuthFlowController, didFinish result: FinancialConnectionsSheet.Result) {
        guard let viewController = navigationController.topViewController else {
            assertionFailure("Navigation stack is empty")
            return
        }
        delegate?.hostController(self, viewController: viewController, didFinish: result)
    }
}

