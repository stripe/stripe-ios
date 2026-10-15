//
//  Checkout+Session+AddressMerging.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 3/2/26.
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripePayments

extension CheckoutController.Session {

    /// Populates empty fields in the configuration with checkout-collected addresses.
    /// Default contact details take precedence over checkout-collected values.
    /// Billing address collection follows the Checkout Session.
    func applyAddressOverrides<C: PaymentElementConfiguration>(to configuration: inout C) {
        if let shipping = shippingAddress, configuration.shippingDetails() == nil {
            let details = shippingAddressDetails(from: shipping)
            configuration.shippingDetails = { details }
        }
        configuration.defaultBillingDetails.email = configuration.defaultBillingDetails.email ?? email
        configuration.billingDetailsCollectionConfiguration.address = billingAddressCollection == .required ? .full : .automatic
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
