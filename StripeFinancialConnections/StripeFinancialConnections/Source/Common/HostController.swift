//
//  HostController.swift
//  StripeFinancialConnections
//
//  Created by Vardges Avetisyan on 6/3/22.
//

@_spi(STP) import StripeCore
import UIKit

/// An internal result type that helps us handle both
/// Financial Connections and Instant Debits
@_spi(STP) public enum HostControllerResult {
    case completed(Completed)
    case failed(error: Error)
    case canceled

    @_spi(STP) public enum Completed {
        case financialConnections(StripeAPI.FinancialConnectionsSession)
        case instantDebits(InstantDebitsLinkedBank)
    }
}

protocol HostControllerDelegate: AnyObject {

    func hostController(
        _ hostController: HostController,
        viewController: UIViewController,
        didFinish result: HostControllerResult
    )

    func hostController(
        _ hostController: HostController,
        didReceiveEvent event: FinancialConnectionsEvent
    )
}

class HostController {

    // MARK: - Properties

    private let api: FinancialConnectionsAPIClient
    private let clientSecret: String
    private let returnURL: String?
    private let analyticsClient: FinancialConnectionsAnalyticsClient

    private var nativeFlowController: NativeFlowController?
    lazy var hostViewController = HostViewController(
        clientSecret: clientSecret,
        returnURL: returnURL,
        apiClient: api,
        delegate: self
    )
    lazy var navigationController = FinancialConnectionsNavigationController(rootViewController: hostViewController)

    weak var delegate: HostControllerDelegate?

    // MARK: - Init

    init(
        api: FinancialConnectionsAPIClient,
        clientSecret: String,
        returnURL: String?,
        publishableKey: String?,
        stripeAccount: String?
    ) {
        self.api = api
        self.clientSecret = clientSecret
        self.returnURL = returnURL
        self.analyticsClient = FinancialConnectionsAnalyticsClient()
        analyticsClient.setAdditionalParameters(
            linkAccountSessionClientSecret: clientSecret,
            publishableKey: publishableKey,
            stripeAccount: stripeAccount
        )
        analyticsClient.delegate = self
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

    func hostViewController(
        _ viewController: HostViewController,
        didFetch synchronizePayload: FinancialConnectionsSynchronize
    ) {
        delegate?.hostController(self, didReceiveEvent: FinancialConnectionsEvent(name: .open))

        if synchronizePayload.manifest.isProductInstantDebits {
            continueWithWebFlow(synchronizePayload.manifest)
        } else {
            let flowRouter = FlowRouter(
                synchronizePayload: synchronizePayload,
                analyticsClient: analyticsClient
            )
            defer {
                // no matter how we exit this function
                // log exposure to one of the variants if appropriate.
                flowRouter.logExposureIfNeeded()
            }

            guard flowRouter.shouldUseNative else {
                continueWithWebFlow(synchronizePayload.manifest)
                return
            }

            navigationController.configureAppearanceForNative()

            let dataManager = NativeFlowAPIDataManager(
                manifest: synchronizePayload.manifest,
                visualUpdate: synchronizePayload.visual,
                returnURL: returnURL,
                consentPaneModel: synchronizePayload.text?.consentPane,
                apiClient: api,
                clientSecret: clientSecret,
                analyticsClient: analyticsClient
            )
            nativeFlowController = NativeFlowController(
                dataManager: dataManager,
                navigationController: navigationController
            )
            nativeFlowController?.delegate = self
            nativeFlowController?.startFlow()
        }
    }

    func hostViewController(
        _ hostViewController: HostViewController,
        didReceiveEvent event: FinancialConnectionsEvent
    ) {
        delegate?.hostController(self, didReceiveEvent: event)
    }
}

// MARK: - Helpers

private extension HostController {

    func continueWithWebFlow(_ manifest: FinancialConnectionsSessionManifest) {
        delegate?.hostController(
            self,
            didReceiveEvent: FinancialConnectionsEvent(
                name: .flowLaunchedInBrowser
            )
        )

        let accountFetcher = FinancialConnectionsAccountAPIFetcher(api: api, clientSecret: clientSecret)
        let sessionFetcher = FinancialConnectionsSessionAPIFetcher(
            api: api,
            clientSecret: clientSecret,
            accountFetcher: accountFetcher
        )
        let webFlowViewController = FinancialConnectionsWebFlowViewController(
            clientSecret: clientSecret,
            apiClient: api,
            manifest: manifest,
            sessionFetcher: sessionFetcher,
            returnURL: returnURL
        )
        webFlowViewController.delegate = self
        navigationController.setViewControllers([webFlowViewController], animated: true)
    }
}

// MARK: - ConnectionsWebFlowViewControllerDelegate

extension HostController: FinancialConnectionsWebFlowViewControllerDelegate {

    func webFlowViewController(
        _ viewController: FinancialConnectionsWebFlowViewController,
        didFinish result: HostControllerResult
    ) {
        delegate?.hostController(self, viewController: viewController, didFinish: result)
    }

    func webFlowViewController(
        _ webFlowViewController: UIViewController,
        didReceiveEvent event: FinancialConnectionsEvent
    ) {
        delegate?.hostController(self, didReceiveEvent: event)
    }
}

// MARK: - NativeFlowControllerDelegate

extension HostController: NativeFlowControllerDelegate {
    func nativeFlowController(
        _ nativeFlowController: NativeFlowController,
        didFinish result: FinancialConnectionsSheet.Result
    ) {
        guard let viewController = navigationController.topViewController else {
            assertionFailure("Navigation stack is empty")
            return
        }
        let hostControllerResult: HostControllerResult
        switch result {
        case .completed(let session):
            hostControllerResult = .completed(.financialConnections(session))
        case .canceled:
            hostControllerResult = .canceled
        case .failed(let error):
            hostControllerResult = .failed(error: error)
        }
        delegate?.hostController(self, viewController: viewController, didFinish: hostControllerResult)
    }

    func nativeFlowController(
        _ nativeFlowController: NativeFlowController,
        didReceiveEvent event: FinancialConnectionsEvent
    ) {
        delegate?.hostController(self, didReceiveEvent: event)
    }
}

// MARK: - FinancialConnectionsAnalyticsClientDelegate

extension HostController: FinancialConnectionsAnalyticsClientDelegate {

    func analyticsClient(
        _ analyticsClient: FinancialConnectionsAnalyticsClient,
        didReceiveEvent event: FinancialConnectionsEvent
    ) {
        delegate?.hostController(self, didReceiveEvent: event)
    }
}
