//
//  ShippingAddressUpdate.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 3/2/26.
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

import Foundation

@_spi(CheckoutSessionsPreview)
extension Checkout {
    /// Parameters for ``updateShippingAddress(_:)``.
    public struct ShippingAddressUpdate {
        /// The customer's full name.
        public let name: String?

        /// The customer's shipping address.
        public let address: Address

        /// Creates a shipping address update.
        /// - Parameters:
        ///   - name: The customer's full name.
        ///   - address: The customer's shipping address.
        public init(name: String? = nil, address: Address) {
            self.name = name
            self.address = address
        }
    }
}
