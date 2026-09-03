//
//  Checkout+PresentmentDetails.swift
//  StripePaymentSheet
//
//  Created by Yuki Tokuhiro on 8/17/26.
//

import Foundation

@_spi(STP)
@_spi(ReactNativeSDK)
extension CheckoutController.Session {
    /// Details about the currency presented to the customer when adaptive pricing is active.
    public struct PresentmentDetails: Sendable, Hashable {
        /// Currency presented to the customer during payment.
        public let presentmentCurrency: String
    }
}
