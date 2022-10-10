//
//  HostController.swift
//  StripeFinancialConnections
//
//  Created by Vardges Avetisyan on 6/3/22.
//

import UIKit

@available(iOSApplicationExtension, unavailable)
protocol HostControllerDelegate: AnyObject {

    func hostController(
        _ hostController: HostController,
        viewController: UIViewController,
        didFinish result: FinancialConnectionsSheet.Result
    )
}

@available(iOSApplicationExtension, unavailable)
class HostController {
    
    // MARK: - Properties
    
    private let api: FinancialConnectionsAPIClient
    private let clientSecret: String
    private let returnURL: String?

    private var authFlowController: AuthFlowController?
    lazy var hostViewController = HostViewController(clientSecret: clientSecret, returnURL: returnURL, apiClient: api, delegate: self)
    lazy var navigationController = FinancialConnectionsNavigationController(rootViewController: hostViewController)

    weak var delegate: HostControllerDelegate?
    
    // Temporary way to control which flow to use
    var useNative = true
    
    // MARK: - Init
    
    init(api: FinancialConnectionsAPIClient,
         clientSecret: String,
         returnURL: String?) {
        self.api = api
        self.clientSecret = clientSecret
        self.returnURL = returnURL
    }
}

// MARK: - HostViewControllerDelegate

@available(iOSApplicationExtension, unavailable)
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
        
        navigationController.configureAppearanceForNative()

        let dataManager = AuthFlowAPIDataManager(
            manifest: manifest,
            apiClient: api,
            clientSecret: clientSecret
        )
        authFlowController = AuthFlowController(
            dataManager: dataManager,
            navigationController: navigationController
        )
        authFlowController?.delegate = self
        authFlowController?.startFlow()
    }
}

// MARK: - Helpers

@available(iOSApplicationExtension, unavailable)
private extension HostController {
    
    func continueWithWebFlow(_ manifest: FinancialConnectionsSessionManifest) {
        let accountFetcher = FinancialConnectionsAccountAPIFetcher(api: api, clientSecret: clientSecret)
        let sessionFetcher = FinancialConnectionsSessionAPIFetcher(api: api, clientSecret: clientSecret, accountFetcher: accountFetcher)
        let webFlowViewController = FinancialConnectionsWebFlowViewController(clientSecret: clientSecret,
                                                                          apiClient: api,
                                                                          manifest: manifest,
                                                                          sessionFetcher: sessionFetcher,
                                                                          returnURL: returnURL)
        webFlowViewController.delegate = self
        navigationController.setViewControllers([webFlowViewController], animated: true)
    }
}

// MARK: - ConnectionsWebFlowViewControllerDelegate

@available(iOSApplicationExtension, unavailable)
extension HostController: FinancialConnectionsWebFlowViewControllerDelegate {
    func financialConnectionsWebFlow(viewController: FinancialConnectionsWebFlowViewController, didFinish result: FinancialConnectionsSheet.Result) {
        delegate?.hostController(self, viewController: viewController, didFinish: result)
    }
}

@available(iOSApplicationExtension, unavailable)
extension HostController: AuthFlowControllerDelegate {
    func authFlow(controller: AuthFlowController, didFinish result: FinancialConnectionsSheet.Result) {
        guard let viewController = navigationController.topViewController else {
            assertionFailure("Navigation stack is empty")
            return
        }
        delegate?.hostController(self, viewController: viewController, didFinish: result)
    }
}

