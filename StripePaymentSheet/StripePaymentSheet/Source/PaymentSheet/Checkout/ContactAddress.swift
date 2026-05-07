//
//  ContactAddress.swift
//  StripePaymentSheet
//
import Foundation

@_spi(STP)
@_spi(ReactNativeSDK)
extension Checkout {
    /// Contact details and a postal address captured for billing or shipping.
    public struct ContactAddress: Equatable, Hashable, Sendable {
        /// The customer's full name.
        public let name: String?

        /// The customer's phone number.
        public let phone: String?

        /// The customer's postal address.
        public let address: Address

        /// Creates contact details and a postal address.
        /// - Parameters:
        ///   - name: The customer's full name.
        ///   - phone: The customer's phone number.
        ///   - address: The customer's postal address.
        public init(name: String? = nil, phone: String? = nil, address: Address) {
            self.name = name
            self.phone = phone
            self.address = address
        }
    }
}
