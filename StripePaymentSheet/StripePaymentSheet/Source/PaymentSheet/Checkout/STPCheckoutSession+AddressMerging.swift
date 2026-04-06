//
//  STPCheckoutSession+AddressMerging.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 3/2/26.
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripePayments

extension STPCheckoutSession {

    /// Populates empty fields in the configuration with checkout-collected addresses.
    /// Configuration values always take precedence over checkout-collected values.
    func applyAddressOverrides(to configuration: inout PaymentSheet.Configuration) {
        if let billing = billingAddressOverride {
            applyBillingAddress(billing, to: &configuration.defaultBillingDetails)
        }
        if let shipping = shippingAddressOverride, configuration.shippingDetails() == nil {
            let details = shippingAddressDetails(from: shipping)
            configuration.shippingDetails = { details }
        }
        configuration.defaultBillingDetails.email = configuration.defaultBillingDetails.email ?? customerEmail
    }

    /// Populates empty fields in the embedded configuration with checkout-collected addresses.
    /// Configuration values always take precedence over checkout-collected values.
    func applyAddressOverrides(to configuration: inout EmbeddedPaymentElement.Configuration) {
        if let billing = billingAddressOverride {
            applyBillingAddress(billing, to: &configuration.defaultBillingDetails)
        }
        if let shipping = shippingAddressOverride, configuration.shippingDetails() == nil {
            let details = shippingAddressDetails(from: shipping)
            configuration.shippingDetails = { details }
        }
        configuration.defaultBillingDetails.email = configuration.defaultBillingDetails.email ?? customerEmail
    }

    private func shippingAddressDetails(from shipping: Checkout.AddressUpdate) -> AddressViewController.AddressDetails {
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
            phone: shipping.phone
        )
    }

    private func applyBillingAddress(
        _ billing: Checkout.AddressUpdate,
        to details: inout PaymentSheet.BillingDetails
    ) {
        details.name = details.name ?? billing.name
        details.phone = details.phone ?? billing.phone
        details.address.country = details.address.country ?? billing.address.country
        details.address.line1 = details.address.line1 ?? billing.address.line1
        details.address.line2 = details.address.line2 ?? billing.address.line2
        details.address.city = details.address.city ?? billing.address.city
        details.address.state = details.address.state ?? billing.address.state
        details.address.postalCode = details.address.postalCode ?? billing.address.postalCode
    }
}
