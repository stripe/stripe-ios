//
//  AddressUpdate.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 3/2/26.
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

import Foundation

@_spi(CheckoutSessionsPreview)
extension Checkout {
    /// Parameters for ``updateBillingAddress(_:)`` and ``updateShippingAddress(_:)``.
    public struct AddressUpdate: Equatable {
        /// The customer's full name.
        public let name: String?

        /// The customer's phone number.
        public let phone: String?

        /// The customer's address.
        public let address: Address

        /// Creates an address update.
        /// - Parameters:
        ///   - name: The customer's full name.
        ///   - phone: The customer's phone number.
        ///   - address: The customer's address.
        public init(name: String? = nil, phone: String? = nil, address: Address) {
            self.name = name
            self.phone = phone
            self.address = address
        }
    }
}
