//
//  ShippingAddressElement.swift
//  StripePaymentSheet
//
//  Created by George Birch on 8/4/26.

/// A shipping address form backed by a Checkout Session.
@MainActor
@_spi(STP)
@_spi(ReactNativeSDK)
public final class ShippingAddressElement {

    private(set) var addressViewController: AddressViewController!

    init(checkout: Checkout) {
        let configuration = checkout.configuration.shippingAddressElement.makeAddressViewControllerConfiguration(
            shippingAddress: checkout.session.shippingAddress,
            allowedCountries: checkout.session.allowedShippingCountries,
            apiClient: checkout.apiClient,
            useAutocompleteEndpoints: checkout.session.elementsSession.shouldUseAutocompleteProxyEndpoints
        )
        addressViewController = AddressViewController(
            configuration: configuration,
            delegate: self
        )
    }
}

extension ShippingAddressElement: AddressViewControllerDelegate {
    public func addressViewControllerDidFinish(
        _ addressViewController: AddressViewController,
        with address: AddressViewController.AddressDetails?
    ) {}
}
