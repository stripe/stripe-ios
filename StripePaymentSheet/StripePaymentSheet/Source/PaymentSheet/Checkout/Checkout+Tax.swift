//
//  Checkout+Tax.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 5/7/2026.
//

import Foundation

@_spi(STP)
@_spi(ReactNativeSDK)
extension CheckoutController.Session {
    /// The tax computation status for a checkout session.
    public struct Tax: Sendable, Hashable {
        /// The current tax computation status.
        public let status: Status

        /// The tax computation status of a checkout session.
        public enum Status: Sendable, Hashable {
            /// The final tax amount is computed and the session is ready for confirmation.
            case ready
            /// A shipping address must be provided to calculate tax.
            case requiresShippingAddress
            /// A billing address must be provided to calculate tax.
            case requiresBillingAddress
        }
    }
}
