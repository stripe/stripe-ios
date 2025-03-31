//
//  FinancialConnectionsLite.swift
//  StripePaymentSheet
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

    /// The API Client instance used to make requests to Stripe.
    let apiClient: FCLiteAPIClient = FCLiteAPIClient(backingAPIClient: .shared)

    /// Any additional Elements context useful for the Financial Connections SDK.
    @_spi(STP) public var elementsSessionContext: ElementsSessionContext?

    private var navigationController: UINavigationController?
    private var wrapperViewController: FCLiteModalPresentationWrapper?
    private var completionHandler: ((FinancialConnectionsSDKResult) -> Void)?

    // Strong reference to prevent deallocation.
    private static var activeInstance: FinancialConnectionsLite?

    /// Initializes `FinancialConnectionsLite`.
    /// - Parameters:
    ///   - clientSecret: The client secret of a Stripe `FinancialConnectionsSession` object.
    ///   - returnUrl: A URL that that `FinancialConnectionsLite` can use to redirect back to your app after completing authentication in another app (such as a bank's app or Safari).
    @_spi(STP) public init(
        clientSecret: String,
        returnUrl: URL?
    ) {
        self.clientSecret = clientSecret
        self.returnUrl = returnUrl
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

        let containerVC = FCLiteContainerViewController(
            clientSecret: clientSecret,
            returnUrl: returnUrl,
            apiClient: apiClient,
            elementsSessionContext: elementsSessionContext,
            completion: { [weak self] result in
                guard let self else { return }
                self.handleFlowCompletion(result: result)
            }
        )

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

    private func handleFlowCompletion(result: FinancialConnectionsSDKResult) {
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

    private func cleanupReferences() {
        self.navigationController = nil
        self.wrapperViewController = nil
        Self.activeInstance = nil
    }
}
