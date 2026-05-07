//
//  Checkout+PaymentError.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 5/7/2026.
//

import Foundation

@_spi(STP)
@_spi(ReactNativeSDK)
extension Checkout {
    /// An error encountered the last time a checkout session was confirmed.
    public struct PaymentError: Sendable, Hashable {
        /// An error message suitable for displaying to the customer.
        public let message: String

        public init(message: String) {
            self.message = message
        }
    }
}
