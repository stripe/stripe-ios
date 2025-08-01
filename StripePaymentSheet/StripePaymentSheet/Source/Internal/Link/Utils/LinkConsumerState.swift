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
        paymentDetails.first { $0.isDefault } ?? paymentDetails.single
    }

    var defaultShippingAddress: ShippingAddressesResponse.ShippingAddress? {
        guard let shippingAddresses else {
            return nil
        }
        return shippingAddresses.first { $0.isDefault ?? false } ?? shippingAddresses.single
    }
}

private extension Array {
    var single: Element? {
        return count == 1 ? first : nil
    }
}
