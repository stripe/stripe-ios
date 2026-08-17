//
//  Checkout+PresentmentDetails.swift
//  StripePaymentSheet
//

import Foundation

@_spi(STP)
@_spi(ReactNativeSDK)
extension Checkout.Session {
    /// Details about the currency presented to the customer when adaptive pricing is active.
    public struct PresentmentDetails: Sendable, Hashable {
        /// Three-letter ISO 4217 presentment currency code in lowercase.
        public let presentmentCurrency: String

        public init(presentmentCurrency: String) {
            self.presentmentCurrency = presentmentCurrency
        }
    }
}
