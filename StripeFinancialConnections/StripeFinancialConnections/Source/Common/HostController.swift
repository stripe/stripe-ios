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

extension HostControllerResult {
    
    /// Updates the `HostControllerResult` from the manifest to populate any fields that aren't part of the actual API response,
    /// but that are still necessary to produce the correct result in the host surface.
    func updateWith(_ manifest: FinancialConnectionsSessionManifest) -> Self {
        guard case .completed(.financialConnections(let session)) = self else {
            return self
        }
        
        let instantlyVerified = !manifest.manualEntryUsesMicrodeposits
        
        let updatedSession = StripeAPI.FinancialConnectionsSession(
            clientSecret: session.clientSecret,
            id: session.id,
            accounts: session.accounts,
            livemode: session.livemode,
            paymentAccount: session.paymentAccount?.setInstantlyVerifiedIfNeeded(instantlyVerified),
            bankAccountToken: session.bankAccountToken,
            status: session.status,
            statusDetails: session.statusDetails
        )
        
        return .completed(.financialConnections(updatedSession))
    }
}

private extension StripeAPI.FinancialConnectionsSession.PaymentAccount {
    
    func setInstantlyVerifiedIfNeeded(_ value: Bool) -> Self {
        guard case .bankAccount(var bankAccount) = self else {
            return self
        }
        
        bankAccount.instantlyVerified = value
        return .bankAccount(bankAccount)
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
    private let elementsSessionContext: ElementsSessionContext?
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
        elementsSessionContext: ElementsSessionContext?,
        returnURL: String?,
        publishableKey: String?,
        stripeAccount: String?
    ) {
        self.apiClient = apiClient
        self.analyticsClientV1 = analyticsClientV1
        self.clientSecret = clientSecret
        self.elementsSessionContext = elementsSessionContext
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
            returnURL: returnURL,
            elementsSessionContext: elementsSessionContext
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
            accountPickerPane: synchronizePayload.text?.accountPickerPane,
            apiClient: apiClient,
            clientSecret: clientSecret,
            analyticsClient: analyticsClient,
            elementsSessionContext: elementsSessionContext
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
