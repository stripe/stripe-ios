//
//  FinancialConnectionsLite.swift
//  StripePaymentSheet
//
//  Created by Mat Schmid on 2025-03-12.
//

@_spi(STP) import StripeCore
import UIKit

enum FCLiteError: Error {
    case missingReturnUrl
    case linkedBankUnavailable
}

@_spi(STP) public final class FinancialConnectionsLite {
    /// The client secret of a Stripe `FinancialConnectionsSession` object.
    let clientSecret: String

    /// A URL that that `FinancialConnectionsLite` can use to redirect back to your
    /// app after completing authentication in another app (such as a bank's app or Safari).
    let returnUrl: URL

    /// The API Client instance used to make requests to Stripe.
    let apiClient: FCLiteAPIClient = FCLiteAPIClient(backingAPIClient: .shared)

    // Strong references to prevent deallocation
    private var navigationController: UINavigationController?
    private var wrapperViewController: ModalPresentationWrapperViewController?
    private var completionHandler: ((FinancialConnectionsSDKResult) -> Void)?

    // Static reference to hold the active instance.
    private static var activeInstance: FinancialConnectionsLite?

    /// Initializes `FinancialConnectionsLite`.
    /// - Parameters:
    ///   - clientSecret: The client secret of a Stripe `FinancialConnectionsSession` object.
    ///   - returnUrl: A URL that that `FinancialConnectionsLite` can use to redirect back to your app after completing authentication in another app (such as a bank's app or Safari).
    @_spi(STP) public init(
        clientSecret: String,
        returnUrl: URL
    ) {
        self.clientSecret = clientSecret
        self.returnUrl = returnUrl
    }

    @_spi(STP) public func present(
        from viewController: UIViewController,
        completion: @escaping (FinancialConnectionsSDKResult) -> Void
    ) {
        // Store self as the active instance
        Self.activeInstance = self

        self.completionHandler = { result in
            // Call original completion
            completion(result)
            // Clear the active instance reference
            Self.activeInstance = nil
        }

        let containerVC = ContainerViewController(
            clientSecret: clientSecret,
            returnUrl: returnUrl,
            apiClient: apiClient,
            completion: { [weak self] result in
                guard let self else { return }
                self.handleFlowCompletion(result: result)
            }
        )

        let navController = UINavigationController(rootViewController: containerVC)
        navController.navigationBar.isHidden = true
        self.navigationController = navController

        let toPresent: UIViewController
        let animated: Bool

        if UIDevice.current.userInterfaceIdiom == .pad {
            navController.modalPresentationStyle = .formSheet
            toPresent = navController
            animated = true
        } else {
            wrapperViewController = ModalPresentationWrapperViewController(vc: navController)
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
        // Clear all references to avoid memory leaks
        self.navigationController = nil
        self.wrapperViewController = nil
    }
}
