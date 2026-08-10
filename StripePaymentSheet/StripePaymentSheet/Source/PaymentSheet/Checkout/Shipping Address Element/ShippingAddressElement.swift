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
}

extension ShippingAddressElement: AddressViewControllerDelegate {
    public func addressViewControllerDidFinish(
        _ addressViewController: AddressViewController,
        with address: AddressViewController.AddressDetails?
    ) {
        // TODO(gbirch): populate when implementing presentation
    }
}
