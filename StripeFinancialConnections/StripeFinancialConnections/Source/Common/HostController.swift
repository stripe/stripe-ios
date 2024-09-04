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

    private let apiClient: FinancialConnectionsAPIClient
    private let clientSecret: String
    private let returnURL: String?
    private let analyticsClient: FinancialConnectionsAnalyticsClient
    private let analyticsClientV1: STPAnalyticsClientProtocol

    private var nativeFlowController: NativeFlowController?
    lazy var hostViewController = HostViewController(
        analyticsClientV1: analyticsClientV1,
        clientSecret: clientSecret,
        returnURL: returnURL,
        apiClient: apiClient,
        delegate: self
    )
    lazy var navigationController = FinancialConnectionsNavigationController(rootViewController: hostViewController)

    weak var delegate: HostControllerDelegate?

    // MARK: - Init

    init(
        apiClient: FinancialConnectionsAPIClient,
        analyticsClientV1: STPAnalyticsClientProtocol,
        clientSecret: String,
        returnURL: String?,
        publishableKey: String?,
        stripeAccount: String?
    ) {
        self.apiClient = apiClient
        self.analyticsClientV1 = analyticsClientV1
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

        let flowRouter = FlowRouter(
            synchronizePayload: synchronizePayload,
            analyticsClient: analyticsClient
        )

        let flow = flowRouter.flow
        analyticsClientV1.log(
            analytic: FinancialConnectionsSheetFlowDetermined(
                clientSecret: clientSecret,
                flow: flow,
                killswitchActive: flowRouter.killswitchActive
            ),
            apiClient: apiClient.backingAPIClient
        )

        switch flow {
        case .webInstantDebits, .webFinancialConnections:
            continueWithWebFlow(synchronizePayload.manifest)
        case .nativeInstantDebits, .nativeFinancialConnections:
            continueWithNativeFlow(synchronizePayload)
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

        let accountFetcher = FinancialConnectionsAccountAPIFetcher(api: apiClient, clientSecret: clientSecret)
        let sessionFetcher = FinancialConnectionsSessionAPIFetcher(
            api: apiClient,
            clientSecret: clientSecret,
            accountFetcher: accountFetcher
        )
        let webFlowViewController = FinancialConnectionsWebFlowViewController(
            clientSecret: clientSecret,
            apiClient: apiClient,
            manifest: manifest,
            sessionFetcher: sessionFetcher,
            returnURL: returnURL
        )
        webFlowViewController.delegate = self
        navigationController.setViewControllers([webFlowViewController], animated: true)
    }

    func continueWithNativeFlow(_ synchronizePayload: FinancialConnectionsSynchronize) {
        navigationController.configureAppearanceForNative()

        let dataManager = NativeFlowAPIDataManager(
            manifest: synchronizePayload.manifest,
            visualUpdate: synchronizePayload.visual,
            returnURL: returnURL,
            consentPaneModel: synchronizePayload.text?.consentPane,
            apiClient: apiClient,
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
        didFinish result: HostControllerResult
    ) {
        guard let viewController = navigationController.topViewController else {
            assertionFailure("Navigation stack is empty")
            return
        }
        delegate?.hostController(self, viewController: viewController, didFinish: result)
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
