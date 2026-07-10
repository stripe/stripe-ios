//
//  STPCheckoutSessionAPIResponse+AddressMerging.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 3/2/26.
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripePayments

extension Checkout {

    /// Populates empty fields in the configuration with Checkout defaults and checkout-collected addresses.
    /// Configuration values always take precedence over Checkout-provided values.
    func applyAddressOverrides<C: PaymentElementConfiguration>(to configuration: inout C) {
        configuration.applyBillingDetailsDefaults(configuration: self.configuration.defaults)
        session.applyAddressOverrides(to: &configuration)
    }
}

extension Checkout.Session {

    /// Populates empty fields in the configuration with checkout-collected addresses.
    /// Configuration values always take precedence over checkout-collected values.
    func applyAddressOverrides<C: PaymentElementConfiguration>(to configuration: inout C) {
        if let billing = billingAddress {
            applyBillingAddress(billing, to: &configuration.defaultBillingDetails)
        }
        if let shipping = shippingAddress, configuration.shippingDetails() == nil {
            let details = shippingAddressDetails(from: shipping)
            configuration.shippingDetails = { details }
        }
        configuration.defaultBillingDetails.email = configuration.defaultBillingDetails.email ?? email
    }

    private func shippingAddressDetails(from shipping: Checkout.ContactAddress) -> AddressViewController.AddressDetails {
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
        _ billing: Checkout.ContactAddress,
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

extension PaymentElementConfiguration {

    fileprivate mutating func applyBillingDetailsDefaults(configuration defaults: Checkout.Configuration.Defaults) {
        guard let billingDetails = defaults.billingDetails else {
            return
        }

        defaultBillingDetails.name = defaultBillingDetails.name ?? billingDetails.name
        defaultBillingDetails.address.country = defaultBillingDetails.address.country ?? billingDetails.address.country
        defaultBillingDetails.address.line1 = defaultBillingDetails.address.line1 ?? billingDetails.address.line1
        defaultBillingDetails.address.line2 = defaultBillingDetails.address.line2 ?? billingDetails.address.line2
        defaultBillingDetails.address.city = defaultBillingDetails.address.city ?? billingDetails.address.city
        defaultBillingDetails.address.state = defaultBillingDetails.address.state ?? billingDetails.address.state
        defaultBillingDetails.address.postalCode = defaultBillingDetails.address.postalCode ?? billingDetails.address.postalCode
    }
}
