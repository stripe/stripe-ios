//
//  Checkout+Status.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 5/7/2026.
//

import Foundation

@_spi(STP)
@_spi(ReactNativeSDK)
extension CheckoutController.Session {
    /// The status of a checkout session.
    public enum Status: Sendable, Hashable {
        /// The checkout session is still in progress. Payment processing has not started.
        case open
        /// The checkout session has expired. No further processing will occur.
        case expired
        /// The checkout session is complete. Payment processing may still be in progress.
        case complete(PaymentStatus)

        /// The payment status of a completed checkout session.
        public enum PaymentStatus: Sendable, Hashable {
            /// The payment funds are available in your account.
            case paid
            /// The payment funds are not yet available in your account.
            case unpaid
            /// The payment is delayed to a future date, or the session is in setup mode
            /// and doesn't require a payment at this time.
            case noPaymentRequired
        }
    }
}
