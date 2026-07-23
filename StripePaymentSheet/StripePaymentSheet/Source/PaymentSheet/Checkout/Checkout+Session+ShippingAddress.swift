//
//  Checkout+Session+ShippingAddress.swift
//  StripePaymentSheet
//
import Foundation

@_spi(STP)
@_spi(ReactNativeSDK)
extension Checkout.Session {
    /// Shipping address of the customer.
    public struct ShippingAddress: Equatable {
        /// The customer's full name.
        public let name: String?

        /// The customer's shipping address.
        public let address: Checkout.Address

        /// Creates a shipping address.
        /// - Parameters:
        ///   - name: The customer's full name.
        ///   - address: The customer's shipping address.
        public init(name: String? = nil, address: Checkout.Address) {
            self.name = name
            self.address = address
        }
    }
}
