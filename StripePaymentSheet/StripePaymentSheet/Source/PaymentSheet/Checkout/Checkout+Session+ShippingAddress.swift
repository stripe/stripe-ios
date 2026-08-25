//
//  Checkout+Session+ShippingAddress.swift
//  StripePaymentSheet
//
import Foundation
@_spi(STP) import StripePayments

@_spi(STP)
@_spi(ReactNativeSDK)
extension CheckoutController.Session {
    /// Shipping address of the customer.
    public struct ShippingAddress: Equatable, Hashable, Sendable {
        /// The customer's full name.
        public let name: String?

        /// The customer's shipping address.
        public let address: CheckoutController.Address

        /// Creates a shipping address.
        /// - Parameters:
        ///   - name: The customer's full name.
        ///   - address: The customer's shipping address.
        init(name: String? = nil, address: CheckoutController.Address) {
            self.name = name
            self.address = address
        }
    }
}

extension CheckoutController.Session.ShippingAddress {
    var paymentIntentShippingDetailsParams: STPPaymentIntentShippingDetailsParams? {
        guard let name,
              let line1 = address.line1 else {
            return nil
        }

        let addressParams = STPPaymentIntentShippingDetailsAddressParams(line1: line1)
        addressParams.line2 = address.line2
        addressParams.city = address.city
        addressParams.state = address.state
        addressParams.postalCode = address.postalCode
        addressParams.country = address.country
        return STPPaymentIntentShippingDetailsParams(address: addressParams, name: name)
    }
}
