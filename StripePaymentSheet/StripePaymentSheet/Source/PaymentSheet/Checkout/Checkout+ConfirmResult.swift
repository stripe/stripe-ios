//
//  Checkout+ConfirmResult.swift
//  StripePaymentSheet
//
//  Created by Joyce Qin on 7/31/26.
//

@_spi(STP)
@_spi(ReactNativeSDK)
extension Checkout {
    /// The result of confirming a payment in a Checkout Session.
    public enum ConfirmResult {
        /// The payment succeeded.
        case succeeded(paymentStatus: PaymentStatus)
        /// The user canceled the payment.
        case canceled
        /// The payment failed with an error.
        case failed(Error)
    }
}
