//
//  Checkout+Session+AddressMerging.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 3/2/26.
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripePayments

extension Checkout.Session {

    /// Applies Checkout Session customer details to a PaymentElement configuration.
    /// Copies `session.shippingAddress` into `configuration.shippingDetails`,
    /// sets the default billing email from `session.email` when the configuration
    /// has none, and requires full billing address collection when the Checkout
    /// Session requires it.
    func applyAddressOverrides<C: PaymentElementConfiguration>(to configuration: inout C) {
        if let shipping = shippingAddress {
            let details = shippingAddressDetails(from: shipping)
            configuration.shippingDetails = { details }
        }
        configuration.defaultBillingDetails.email = configuration.defaultBillingDetails.email ?? email
        configuration.billingDetailsCollectionConfiguration.address = resolvedAddressCollectionMode(
            serverBillingAddressCollection: billingAddressCollection,
            clientBillingAddressCollection: configuration.billingDetailsCollectionConfiguration.address
        )
    }

    private func shippingAddressDetails(from shipping: ShippingAddress) -> AddressViewController.AddressDetails {
        AddressViewController.AddressDetails(
            address: .init(
                city: shipping.address.city,
                country: shipping.address.country,
                line1: shipping.address.line1 ?? "",
                line2: shipping.address.line2,
                postalCode: shipping.address.postalCode,
                state: shipping.address.state
            ),
            name: shipping.name,
            phone: nil
        )
    }

    private func resolvedAddressCollectionMode(
        serverBillingAddressCollection: BillingAddressCollection,
        clientBillingAddressCollection: PaymentSheet.BillingDetailsCollectionConfiguration.AddressCollectionMode
    ) -> PaymentSheet.BillingDetailsCollectionConfiguration.AddressCollectionMode {
        switch (serverBillingAddressCollection, clientBillingAddressCollection) {
        case (.required, .automatic), (.required, .full):
            return .full
        case (.required, .never):
            assertionFailure("billingDetailsCollectionConfiguration.address = .never is not supported with CheckoutSession.")
            return .never
        case (.automatic, let clientBillingAddressCollection):
            return clientBillingAddressCollection
        }
    }

}
