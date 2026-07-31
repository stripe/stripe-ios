//
//  Checkout+ConfirmResult.swift
//  StripePaymentSheet
//

import Foundation

@_spi(STP)
@_spi(ReactNativeSDK)
extension Checkout {
    /// The result of confirming a Checkout Session.
    public enum ConfirmResult {
        /// The Checkout Session was confirmed successfully.
        case succeeded(paymentStatus: PaymentStatus)
        /// The customer canceled the payment.
        case canceled
        /// Confirmation failed with an error.
        case failed(Error)
    }
}
