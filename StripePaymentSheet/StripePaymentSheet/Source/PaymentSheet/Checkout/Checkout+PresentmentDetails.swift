//
//  Checkout+PresentmentDetails.swift
//  StripePaymentSheet
//
//  Created by Yuki Tokuhiro on 8/17/26.
//

import Foundation

@_spi(STP)
@_spi(ReactNativeSDK)
extension Checkout.Session {
    /// Details about the currency presented to the customer when adaptive pricing is active.
    public struct PresentmentDetails: Sendable, Hashable {
        /// Three-letter ISO 4217 presentment currency code in lowercase.
        public let presentmentCurrency: String
    }
}
