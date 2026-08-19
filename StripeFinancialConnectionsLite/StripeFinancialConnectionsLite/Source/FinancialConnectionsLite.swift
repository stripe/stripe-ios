//
//  FinancialConnectionsLite.swift
//  StripeFinancialConnectionsLite
//
//  Created by Mat Schmid on 2025-03-19.
//

@_spi(STP) import StripeCore
import UIKit

@_spi(STP) public final class FinancialConnectionsLite {
    /// The client secret of a Stripe `FinancialConnectionsSession` object.
    let clientSecret: String

    /// A URL that `FinancialConnectionsLite` can use to redirect back to your
    /// app after completing authentication in another app (such as a bank's app or Safari).
    /// If not provided, all bank authentication sessions will happen in a secure browser within this app.
    let returnUrl: URL?

    /// The API client used for all Financial Connections requests.
    let apiClient: STPAPIClient

    /// Any additional Elements context useful for the Financial Connections SDK.
    @_spi(STP) public var elementsSessionContext: ElementsSessionContext?

    /// A existing consumer, if avaialble.
    @_spi(STP) public var existingConsumer: FinancialConnectionsConsumer?

    /// The consumer publishable key to use for requests, if available.
    /// Takes precedence over `existingConsumer?.publishableKey`.
    @_spi(STP) public var consumerPublishableKey: String?

    /// Details used to prefill the Link login pane, if available.
    @_spi(STP) public var prefillDetails: WebPrefillDetails?

    private var navigationController: UINavigationController?
    private var wrapperViewController: FCLiteModalPresentationWrapper?
    private var completionHandler: ((FinancialConnectionsSDKResult) -> Void)?

    private enum PresentationMode {
        case standalone
        case embedded
    }
    private var presentationMode: PresentationMode = .standalone

    // Strong reference to prevent deallocation.
    private static var activeInstance: FinancialConnectionsLite?

    /// Initializes `FinancialConnectionsLite`.
    /// - Parameters:
    ///   - clientSecret: The client secret of a Stripe `FinancialConnectionsSession` object.
    ///   - returnUrl: A URL that that `FinancialConnectionsLite` can use to redirect back to your app after completing authentication in another app (such as a bank's app or Safari).
    ///   - apiClient: The API client to use for requests. Defaults to `STPAPIClient.shared`.
    @_spi(STP) public init(
        clientSecret: String,
        returnUrl: URL?,
        apiClient: STPAPIClient = .shared
    ) {
        self.clientSecret = clientSecret
        self.returnUrl = returnUrl
        self.apiClient = apiClient
    }

    /// Launches the Financial Connections flow on the provided view controller.
    /// - Parameters:
    ///   - viewController: The view controller from which the pay by bank flow will be presented.
    ///   - completion: A closure that gets called with the result of the Financial Connections flow.
    @_spi(STP) public func present(
        from viewController: UIViewController,
        completion: @escaping (FinancialConnectionsSDKResult) -> Void
    ) {
        Self.activeInstance = self
        self.completionHandler = completion
        self.presentationMode = .standalone

        let containerVC = makeContainerViewController()

        let navController = UINavigationController(rootViewController: containerVC)
        navController.navigationBar.isHidden = true
        navController.overrideUserInterfaceStyle = .light
        self.navigationController = navController

        let toPresent: UIViewController
        let animated: Bool

        if UIDevice.current.userInterfaceIdiom == .pad {
            navController.preferredContentSize = CGSize(width: 360, height: 580)
            navController.modalPresentationStyle = .formSheet
            toPresent = navController
            animated = true
        } else {
            wrapperViewController = FCLiteModalPresentationWrapper(vc: navController)
            toPresent = wrapperViewController!
            animated = false
        }

        viewController.present(toPresent, animated: animated)
    }

    /// Embeds the Financial Connections flow into the provided navigation controller, replacing its
    /// current view controller stack in place, rather than presenting a new modal on top of it.
    /// Use this when the caller already owns a presented navigation controller (e.g. as a fallback
    /// from a flow already on screen) to avoid stacking a second modal sheet.
    /// - Parameters:
    ///   - navigationController: An already-presented navigation controller to embed the flow into.
    ///   - completion: A closure that gets called with the result of the Financial Connections flow.
    @_spi(STP) public func present(
        embeddedIn navigationController: UINavigationController,
        completion: @escaping (FinancialConnectionsSDKResult) -> Void
    ) {
        Self.activeInstance = self
        self.completionHandler = completion
        self.presentationMode = .embedded

        let containerVC = makeContainerViewController()

        navigationController.setNavigationBarHidden(true, animated: false)
        navigationController.setViewControllers([containerVC], animated: false)
    }

    private func makeContainerViewController() -> FCLiteContainerViewController {
        var fcLiteApiClient = FCLiteAPIClient(backingAPIClient: apiClient)
        fcLiteApiClient.consumerPublishableKey = consumerPublishableKey ?? existingConsumer?.publishableKey

        return FCLiteContainerViewController(
            clientSecret: clientSecret,
            returnUrl: returnUrl,
            apiClient: fcLiteApiClient,
            elementsSessionContext: elementsSessionContext,
            prefillDetails: prefillDetails,
            completion: { [weak self] result in
                guard let self else { return }
                self.handleFlowCompletion(result: result)
            }
        )
    }

    func handleFlowCompletion(result: FinancialConnectionsSDKResult) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }

            guard self.presentationMode == .standalone else {
                // We were embedded into a navigation controller we don't own, so the caller
                // (e.g. HostController/FinancialConnectionsSheet) is responsible for the one
                // outer-modal dismiss. There's nothing for us to dismiss ourselves.
                guard let completion = self.completionHandler else { return }
                self.cleanupReferences()
                completion(result)
                return
            }

            // First dismiss the navigation controller
            self.navigationController?.dismiss(animated: true) { [weak self] in
                guard let self else { return }

                // Dismiss the wrapper if it exists
                if let wrapper = self.wrapperViewController {
                    wrapper.dismiss(animated: false) { [weak self] in
                        guard let self, let completion = self.completionHandler else { return }

                        // Clear references and call the completion handler
                        self.cleanupReferences()
                        completion(result)
                    }
                } else {
                    // No wrapper, just clean up and call completion directly
                    guard let completion = self.completionHandler else { return }
                    self.cleanupReferences()
                    completion(result)
                }
            }
        }
    }

    private func cleanupReferences() {
        self.navigationController = nil
        self.wrapperViewController = nil
        self.presentationMode = .standalone
        Self.activeInstance = nil
    }
}
