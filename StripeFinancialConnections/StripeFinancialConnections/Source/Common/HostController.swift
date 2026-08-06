//
//  HostController.swift
//  StripeFinancialConnections
//
//  Created by Vardges Avetisyan on 6/3/22.
//

@_spi(STP) import StripeCore
@_spi(STP) import StripeFinancialConnectionsLite
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
        case linkedAccount(id: String)
    }

    var linkAccountSessionId: String? {
        guard case .completed(let completed) = self else { return nil }
        switch completed {
        case .financialConnections(let session):
            return session.id
        case .instantDebits(let linkedBank):
            return linkedBank.linkAccountSessionId
        case .linkedAccount(let id):
            return id
        }
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
        didFinish result: HostControllerResult,
        linkAccountSessionId: String?
    )

    func hostController(
        _ hostController: HostController,
        didReceiveEvent event: FinancialConnectionsEvent
    )
}

class HostController {

    // MARK: - Properties

    private let apiClient: any FinancialConnectionsAPI
    private let clientSecret: String
    private let returnURL: String?
    private let configuration: FinancialConnectionsSheet.Configuration
    private let elementsSessionContext: ElementsSessionContext?
    private let analyticsClient: FinancialConnectionsAnalyticsClient
    private let analyticsClientV1: STPAnalyticsClientProtocol

    private var nativeFlowController: NativeFlowController?
    private var financialConnectionsLite: FinancialConnectionsLite?
    private var linkAccountSessionId: String?
    lazy var hostViewController = HostViewController(
        analyticsClientV1: analyticsClientV1,
        clientSecret: clientSecret,
        returnURL: returnURL,
        apiClient: apiClient,
        delegate: self
    )
    lazy var navigationController: FinancialConnectionsNavigationController = {
        let navigationController = FinancialConnectionsNavigationController(rootViewController: hostViewController)
        configuration.style.configure(navigationController)
        return navigationController
    }()

    weak var delegate: HostControllerDelegate?

    // MARK: - Init

    init(
        apiClient: any FinancialConnectionsAPI,
        analyticsClientV1: STPAnalyticsClientProtocol,
        clientSecret: String,
        returnURL: String?,
        configuration: FinancialConnectionsSheet.Configuration,
        elementsSessionContext: ElementsSessionContext?,
        publishableKey: String?,
        stripeAccount: String?
    ) {
        self.apiClient = apiClient
        self.analyticsClientV1 = analyticsClientV1
        self.clientSecret = clientSecret
        self.returnURL = returnURL
        self.configuration = configuration
        self.elementsSessionContext = elementsSessionContext
        self.analyticsClient = FinancialConnectionsAnalyticsClient()
        analyticsClient.setAdditionalParameters(
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
            delegate?.hostController(
                self,
                viewController: viewController,
                didFinish: .canceled,
                linkAccountSessionId: linkAccountSessionId
            )
            return
        }

        delegate?.hostController(
            self,
            viewController: viewController,
            didFinish: .failed(error: error),
            linkAccountSessionId: linkAccountSessionId
        )
    }

    func hostViewController(
        _ viewController: HostViewController,
        didFetch synchronizePayload: FinancialConnectionsSynchronize
    ) {
        delegate?.hostController(self, didReceiveEvent: FinancialConnectionsEvent(name: .open))
        self.linkAccountSessionId = synchronizePayload.manifest.id

        let flowRouter = FlowRouter(
            synchronizePayload: synchronizePayload,
            analyticsClient: analyticsClient
        )

        let flow = flowRouter.flow
        analyticsClientV1.log(
            analytic: FinancialConnectionsSheetFlowDetermined(
                linkAccountSessionId: synchronizePayload.manifest.id,
                flow: flow,
                killswitchActive: flowRouter.killswitchActive
            ),
            apiClient: apiClient.backingAPIClient
        )

        switch flow {
        case .webInstantDebits, .webFinancialConnections:
            continueWithFCLite(synchronizePayload.manifest)
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

extension HostController {

    private func continueWithFCLite(
        _ manifest: FinancialConnectionsSessionManifest,
        prefillDetails: WebPrefillDetails? = nil
    ) {
        delegate?.hostController(
            self,
            didReceiveEvent: FinancialConnectionsEvent(
                name: .flowLaunchedInBrowser
            )
        )

        let financialConnectionsLite = FinancialConnectionsLite(
            clientSecret: clientSecret,
            returnUrl: returnURL.flatMap(URL.init(string:)),
            apiClient: apiClient.backingAPIClient
        )
        financialConnectionsLite.elementsSessionContext = elementsSessionContext
        financialConnectionsLite.consumerPublishableKey = apiClient.consumerPublishableKey
        financialConnectionsLite.prefillDetails = prefillDetails
        self.financialConnectionsLite = financialConnectionsLite

        let presentingViewController = navigationController.topViewController ?? navigationController
        financialConnectionsLite.present(from: presentingViewController) { [weak self] result in
            guard let self else { return }
            self.handleFCLiteResult(result, manifest: manifest)
        }
    }

    /// Adapts FC Lite's `FinancialConnectionsSDKResult` into the `HostControllerResult` expected by
    /// the rest of the SDK. FC Lite only returns a lightweight linked bank for a successful Financial
    /// Connections result, so we re-fetch the full session here to satisfy the host surface.
    func handleFCLiteResult(
        _ result: FinancialConnectionsSDKResult,
        manifest: FinancialConnectionsSessionManifest
    ) {
        switch result {
        case .completed(let completed):
            handleFCLiteCompletion(completed, manifest: manifest)
        case .cancelled:
            handleFCLiteCancellation(manifest: manifest)
        case .failed(let error):
            notifyDelegateOfFailureEvents(error: error)
            finishFromFCLite(.failed(error: error))
        @unknown default:
            let error = FinancialConnectionsSheetError.unknown(
                debugDescription: "Unhandled FinancialConnectionsSDKResult case"
            )
            notifyDelegateOfFailureEvents(error: error)
            finishFromFCLite(.failed(error: error))
        }
    }

    private func handleFCLiteCompletion(
        _ completed: FinancialConnectionsSDKResult.Completed,
        manifest: FinancialConnectionsSessionManifest
    ) {
        switch completed {
        case .financialConnections:
            // FC Lite only returns a lightweight linked bank, so re-fetch the full session.
            fetchSession { [weak self] fetchResult in
                guard let self else { return }
                switch fetchResult {
                case .success(let session):
                    self.notifyDelegateOfSuccessEvent(session: session)
                    self.finishFromFCLite(
                        .completed(.financialConnections(session)).updateWith(manifest)
                    )
                case .failure(let error):
                    self.notifyDelegateOfFailureEvents(error: error)
                    self.finishFromFCLite(.failed(error: error))
                }
            }
        case .instantDebits(let linkedBank):
            notifyDelegateOfSuccessEvent(session: nil)
            finishFromFCLite(.completed(.instantDebits(linkedBank)))
        case .linkedAccount(let id):
            notifyDelegateOfSuccessEvent(session: nil)
            finishFromFCLite(.completed(.linkedAccount(id: id)))
        @unknown default:
            let error = FinancialConnectionsSheetError.unknown(
                debugDescription: "Unhandled FinancialConnectionsSDKResult.Completed case"
            )
            notifyDelegateOfFailureEvents(error: error)
            finishFromFCLite(.failed(error: error))
        }
    }

    /// FC Lite reports a plain cancellation, but the web fallback used to convert a
    /// custom-manual-entry cancellation into a dedicated error. To preserve that behavior we
    /// re-fetch the session on cancel (for Financial Connections only) and check its status.
    func handleFCLiteCancellation(manifest: FinancialConnectionsSessionManifest) {
        guard !manifest.isProductInstantDebits else {
            notifyDelegateOfCancelEvent()
            finishFromFCLite(.canceled)
            return
        }

        fetchSession { [weak self] fetchResult in
            guard let self else { return }
            if case .success(let session) = fetchResult,
               session.status == .cancelled,
               session.statusDetails?.cancelled?.reason == .customManualEntry {
                self.finishFromFCLite(.failed(error: FinancialConnectionsCustomManualEntryRequiredError()))
            } else {
                self.notifyDelegateOfCancelEvent()
                self.finishFromFCLite(.canceled)
            }
        }
    }

    private func fetchSession(
        completion: @escaping (Result<StripeAPI.FinancialConnectionsSession, Error>) -> Void
    ) {
        let accountFetcher = FinancialConnectionsAccountAPIFetcher(api: apiClient, clientSecret: clientSecret)
        let sessionFetcher = FinancialConnectionsSessionAPIFetcher(
            api: apiClient,
            clientSecret: clientSecret,
            accountFetcher: accountFetcher
        )
        sessionFetcher.fetchSession().observe { result in
            completion(result)
        }
    }

    private func finishFromFCLite(_ result: HostControllerResult) {
        let linkAccountSessionId = result.linkAccountSessionId ?? self.linkAccountSessionId
        let viewController = navigationController.topViewController ?? navigationController
        delegate?.hostController(
            self,
            viewController: viewController,
            didFinish: result,
            linkAccountSessionId: linkAccountSessionId
        )
    }

    private func notifyDelegateOfSuccessEvent(session: StripeAPI.FinancialConnectionsSession?) {
        delegate?.hostController(
            self,
            didReceiveEvent: FinancialConnectionsEvent(
                name: .success,
                metadata: FinancialConnectionsEvent.Metadata(
                    manualEntry: session?.paymentAccount?.isManualEntry ?? false
                )
            )
        )
    }

    private func notifyDelegateOfCancelEvent() {
        delegate?.hostController(self, didReceiveEvent: FinancialConnectionsEvent(name: .cancel))
    }

    private func notifyDelegateOfFailureEvents(error: Error) {
        FinancialConnectionsEvent
            .events(fromError: error)
            .forEach { delegate?.hostController(self, didReceiveEvent: $0) }
    }

    private func continueWithNativeFlow(_ synchronizePayload: FinancialConnectionsSynchronize) {
        navigationController.configureAppearanceForNative()

        let dataManager = NativeFlowAPIDataManager(
            manifest: synchronizePayload.manifest,
            configuration: configuration,
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
        let linkAccountSessionId = result.linkAccountSessionId ?? linkAccountSessionId
        delegate?.hostController(
            self,
            viewController: viewController,
            didFinish: result,
            linkAccountSessionId: linkAccountSessionId
        )
    }

    func nativeFlowController(
        _ nativeFlowController: NativeFlowController,
        didReceiveEvent event: FinancialConnectionsEvent
    ) {
        delegate?.hostController(self, didReceiveEvent: event)
    }

    func nativeFlowController(
        _ nativeFlowController: NativeFlowController,
        shouldLaunchWebFlow manifest: FinancialConnectionsSessionManifest,
        prefillDetails: WebPrefillDetails
    ) {
        continueWithFCLite(manifest, prefillDetails: prefillDetails)
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
