//
//  Checkout+Status.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 5/7/2026.
//

import Foundation

@_spi(STP)
@_spi(ReactNativeSDK)
extension Checkout {
    /// The status of a checkout session.
    public struct Status: Sendable, Hashable {
        /// The type of status (open, expired, or complete).
        public let type: StatusType
        /// The payment status. Only meaningful when ``type`` is ``StatusType.complete``.
        public let paymentStatus: PaymentStatus?

        public init(type: StatusType, paymentStatus: PaymentStatus?) {
            self.type = type
            self.paymentStatus = paymentStatus
        }
    }

    /// The lifecycle status of a checkout session.
    public enum StatusType: Sendable, Hashable {
        /// A status not recognized by this version of the SDK.
        case unknown
        /// The checkout session is still in progress. Payment processing has not started.
        case open
        /// The checkout session is complete. Payment processing may still be in progress.
        case complete
        /// The checkout session has expired. No further processing will occur.
        case expired
    }

    /// The payment status of a checkout session.
    public enum PaymentStatus: Sendable, Hashable {
        /// A payment status not recognized by this version of the SDK.
        case unknown
        /// The payment funds are available in your account.
        case paid
        /// The payment funds are not yet available in your account.
        case unpaid
        /// The payment is delayed to a future date, or the session is in setup mode
        /// and doesn't require a payment at this time.
        case noPaymentRequired
    }
}
