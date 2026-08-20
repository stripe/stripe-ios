//
//  Checkout+Session+AddressMerging.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 3/2/26.
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripePayments

/// A billing address collection mode, implemented by both ``PaymentSheet/BillingDetailsCollectionConfiguration/AddressCollectionMode``
/// and ``ExpressCheckoutElement/BillingDetailsCollectionConfiguration/AddressCollectionMode``, so server-driven
/// billing address requirements can be resolved against either one generically.
protocol BillingAddressCollectionMode: Equatable {
    static var automatic: Self { get }
    static var full: Self { get }
    /// The "never collect the address" case, if this mode supports one, else `nil`. `ExpressCheckoutElement`'s
    /// mode doesn't have one, since Apple Pay always collects at least the postal code.
    static var neverCase: Self? { get }
}

extension PaymentSheet.BillingDetailsCollectionConfiguration.AddressCollectionMode: BillingAddressCollectionMode {
    static var neverCase: Self? { .never }
}

extension ExpressCheckoutElement.BillingDetailsCollectionConfiguration.AddressCollectionMode: BillingAddressCollectionMode {
    static var neverCase: Self? { nil }
}

extension CheckoutController.Session {

    /// Populates empty fields in the configuration with checkout-collected addresses.
    /// Configuration values always take precedence over checkout-collected values.
    func applyAddressOverrides<C: PaymentElementConfiguration>(to configuration: inout C) {
        if let shipping = shippingAddress, configuration.shippingDetails() == nil {
            let details = shippingAddressDetails(from: shipping)
            configuration.shippingDetails = { details }
        }
        configuration.defaultBillingDetails.email = configuration.defaultBillingDetails.email ?? email
        configuration.billingDetailsCollectionConfiguration.address = resolvedAddressCollectionMode(
            serverBillingAddressCollection: billingAddressCollection,
            clientBillingAddressCollection: configuration.billingDetailsCollectionConfiguration.address
        )
    }

    /// Upgrades `configuration`'s billing address collection mode to `.full` when the Checkout Session
    /// requires a billing address.
    func applyBillingAddressCollectionOverride(to configuration: inout ExpressCheckoutElement.Configuration) {
        configuration.billingDetailsCollectionConfiguration.address = resolvedAddressCollectionMode(
            serverBillingAddressCollection: billingAddressCollection,
            clientBillingAddressCollection: configuration.billingDetailsCollectionConfiguration.address
        )
    }

    private func resolvedAddressCollectionMode<Mode: BillingAddressCollectionMode>(
        serverBillingAddressCollection: BillingAddressCollection,
        clientBillingAddressCollection: Mode
    ) -> Mode {
        switch serverBillingAddressCollection {
        case .automatic:
            return clientBillingAddressCollection
        case .required:
            if let neverCase = Mode.neverCase, clientBillingAddressCollection == neverCase {
                assertionFailure("billingDetailsCollectionConfiguration.address = .never is not supported with CheckoutSession.")
                return clientBillingAddressCollection
            }
            return .full
        }
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

}
