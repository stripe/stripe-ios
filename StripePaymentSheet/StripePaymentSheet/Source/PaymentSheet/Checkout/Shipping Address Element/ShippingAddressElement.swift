//
//  ShippingAddressElement.swift
//  StripePaymentSheet
//
//  Created by George Birch on 8/4/26.

@_spi(STP) import StripeCore
import UIKit

/// A shipping address form backed by a Checkout Session.
@MainActor
@_spi(STP)
@_spi(ReactNativeSDK)
public final class ShippingAddressElement {

    private(set) var addressViewController: AddressViewController!
    private var presentationCompletion: (() -> Void)?
    private var isDismissingPresentation = false

    init(
        configuration: Configuration,
        initialShippingAddress: Checkout.Session.ShippingAddress?,
        allowedCountries: [String]?,
        apiClient: STPAPIClient,
        useAutocompleteEndpoints: Bool
    ) {
        let addressViewControllerConfiguration = configuration.makeAddressViewControllerConfiguration(
            shippingAddress: initialShippingAddress,
            allowedCountries: allowedCountries,
            apiClient: apiClient,
            useAutocompleteEndpoints: useAutocompleteEndpoints
        )
        addressViewController = AddressViewController(
            configuration: addressViewControllerConfiguration,
            delegate: self
        )
    }

    /// Presents a sheet that collects the customer's shipping address.
    /// - Parameter from: The view controller that presents the sheet. If you're using SwiftUI, you may pass nil and it will use the topmost UIViewController from the key window.
    /// Returns when the sheet is dismissed.
    public func present(from presentingViewController: UIViewController? = nil) async {
        await withCheckedContinuation { continuation in
            present(from: presentingViewController) {
                continuation.resume()
            }
        }
    }

    /// Presents a sheet that collects the customer's shipping address.
    /// - Parameter from: The view controller that presents the sheet. If you're using SwiftUI, you may pass nil and it will use the topmost UIViewController from the key window.
    /// - Parameter completion: Called when the sheet is dismissed.
    public func present(
        from presentingViewController: UIViewController? = nil,
        completion: (() -> Void)? = nil
    ) {
        guard let presentingViewController = presentingViewController ?? UIWindow.visibleViewController else {
            let errorMessage = "ShippingAddressElement.present(from:) could not find a presenting view controller."
            assertionFailure(errorMessage)
            let analytic = UnexpectedCheckoutElementsErrorAnalytic(
                errorCode: .shippingAddressElementPresentingViewControllerUnavailable,
                errorMessage: errorMessage
            )
            STPAnalyticsClient.sharedClient.log(analytic: analytic)
            completion?()
            return
        }

        guard presentingViewController.presentedViewController == nil else {
            assertionFailure("presentingViewController is already presenting a view controller")
            completion?()
            return
        }

        let navigationController = UINavigationController(rootViewController: addressViewController)
        presentationCompletion = completion
        presentingViewController.present(navigationController, animated: true)
    }

    private func finishPresentation(for navigationController: UINavigationController) {
        let completion = presentationCompletion
        navigationController.setViewControllers([], animated: false)
        presentationCompletion = nil
        isDismissingPresentation = false
        completion?()
    }
}

extension ShippingAddressElement: AddressViewControllerDelegate {
    public func addressViewControllerDidFinish(
        _ addressViewController: AddressViewController,
        with address: AddressViewController.AddressDetails?
    ) {
        guard let navigationController = addressViewController.navigationController,
              !isDismissingPresentation else {
            return
        }

        isDismissingPresentation = true

        if navigationController.isBeingDismissed,
           let transitionCoordinator = navigationController.transitionCoordinator {
            transitionCoordinator.animate(alongsideTransition: nil) { [weak self, weak navigationController] context in
                guard let self, let navigationController else {
                    return
                }
                if context.isCancelled {
                    isDismissingPresentation = false
                } else {
                    finishPresentation(for: navigationController)
                }
            }
            return
        }

        if navigationController.isBeingDismissed {
            finishPresentation(for: navigationController)
        } else {
            navigationController.dismiss(animated: true) { [weak self, weak navigationController] in
                guard let self, let navigationController else {
                    return
                }
                finishPresentation(for: navigationController)
            }
        }
    }
}
