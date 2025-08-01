//
//  LinkConsumerState.swift
//  StripePaymentSheet
//
//  Created by Till Hellmund on 7/31/25.
//

import Foundation

struct LinkConsumerState {
    let paymentDetails: [ConsumerPaymentDetails]
    let shippingAddresses: [ShippingAddressesResponse.ShippingAddress]?

    var defaultPaymentDetails: ConsumerPaymentDetails? {
        paymentDetails.first { $0.isDefault } ?? paymentDetails.first
    }

    var defaultShippingAddress: ShippingAddressesResponse.ShippingAddress? {
        shippingAddresses?.first { $0.isDefault ?? false } ?? shippingAddresses?.first
    }
}
