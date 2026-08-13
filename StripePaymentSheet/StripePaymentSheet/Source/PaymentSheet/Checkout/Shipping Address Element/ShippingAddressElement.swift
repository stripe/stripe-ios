//
//  ShippingAddressElement.swift
//  StripePaymentSheet
//
//  Created by George Birch on 8/4/26.

@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
import UIKit

/// Handles Checkout mutations requested by a ShippingAddressElement.
@MainActor
protocol ShippingAddressElementDelegate: AnyObject {
    /// Sets the customer's shipping address.
    func updateShippingAddress(name: String?, address: Checkout.Address) async throws
}

/// A shipping address form backed by a Checkout Session.
@MainActor
@_spi(STP)
@_spi(ReactNativeSDK)
public final class ShippingAddressElement {

    private(set) var addressViewController: AddressViewController!
    private var isPresenting = false
    private var presentationCompletion: (() -> Void)?
    weak var delegate: ShippingAddressElementDelegate?

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
            addressSpecProvider: .shared,
            configuration: addressViewControllerConfiguration,
            delegate: self,
            integrationDelegate: self
        )
    }

    func normalizedInitialShippingAddress() async -> Checkout.Session.ShippingAddress? {
        // Read the address back from the form to include its validation and normalization.
        guard let addressDetails = await addressViewController.initialAddressDetails() else {
            return nil
        }
        return Checkout.Session.ShippingAddress(
            name: addressDetails.name,
            address: Checkout.Address(
                country: addressDetails.address.country,
                line1: addressDetails.address.line1,
                line2: addressDetails.address.line2,
                city: addressDetails.address.city,
                state: addressDetails.address.state,
                postalCode: addressDetails.address.postalCode
            )
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
        guard !isPresenting else {
            assertionFailure("ShippingAddressElement is already presenting")
            completion?()
            return
        }

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
        isPresenting = true
        presentationCompletion = completion
        presentingViewController.present(navigationController, animated: true)
    }
}

extension ShippingAddressElement: AddressViewController.IntegrationDelegate {
    func save(addressDetails: AddressViewController.AddressDetails) async throws {
        guard let delegate else {
            stpAssertionFailure("ShippingAddressElement does not have a delegate.")
            return
        }

        try await delegate.updateShippingAddress(
            name: addressDetails.name,
            address: Checkout.Address(
                country: addressDetails.address.country,
                line1: addressDetails.address.line1.nonEmpty,
                line2: addressDetails.address.line2,
                city: addressDetails.address.city,
                state: addressDetails.address.state,
                postalCode: addressDetails.address.postalCode
            )
        )
    }
}

extension ShippingAddressElement: AddressViewControllerDelegate {
    public func addressViewControllerDidFinish(
        _ addressViewController: AddressViewController,
        with address: AddressViewController.AddressDetails?
    ) {
        addressViewController.dismiss(animated: true) {
            let completion = self.presentationCompletion
            self.presentationCompletion = nil
            self.isPresenting = false
            completion?()
        }
    }
}
