//
//  Checkout+Session+Totals.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 5/7/2026.
//

import Foundation

@_spi(STP)
@_spi(ReactNativeSDK)
extension CheckoutController.Session {
    /// Aggregate amounts for a checkout session.
    ///
    /// Use this to render an amount breakdown to your customer in an order summary.
    public struct Totals: Sendable, Hashable {
        /// The total of all order-summary items, excluding tax, discounts, and shipping.
        public let subtotal: CheckoutController.Session.Amount
        /// The sum of all exclusive tax amounts (tax collected in addition to the subtotal).
        public let taxExclusive: CheckoutController.Session.Amount
        /// The sum of all inclusive tax amounts (tax already included in the subtotal).
        public let taxInclusive: CheckoutController.Session.Amount
        /// The sum of all discounts. A positive number reduces the amount to be paid.
        public let discount: CheckoutController.Session.Amount
        /// The grand total, including discounts and tax.
        public let total: CheckoutController.Session.Amount
    }
}
