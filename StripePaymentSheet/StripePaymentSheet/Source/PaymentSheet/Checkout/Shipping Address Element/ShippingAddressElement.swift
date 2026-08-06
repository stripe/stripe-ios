//
//  ShippingAddressElement.swift
//  StripePaymentSheet
//
//  Created by George Birch on 8/4/26.

@_spi(STP) import StripeCore

/// A shipping address form backed by a Checkout Session.
@MainActor
@_spi(STP)
@_spi(ReactNativeSDK)
public final class ShippingAddressElement {

    private(set) var addressViewController: AddressViewController!

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
}

extension ShippingAddressElement: AddressViewControllerDelegate {
    public func addressViewControllerDidFinish(
        _ addressViewController: AddressViewController,
        with address: AddressViewController.AddressDetails?
    ) {
        // TODO(gbirch): populate when implementing presentation
    }
}
