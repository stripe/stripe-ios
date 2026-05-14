//
//  Checkout+Total.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 5/7/2026.
//

import Foundation

@_spi(STP)
@_spi(ReactNativeSDK)
extension Checkout {
    /// Tax and discount details for the computed total amount of a checkout session.
    ///
    /// Use this to render an amount breakdown to your customer in an order summary.
    public struct Total: Sendable, Hashable {
        /// The total of all line items, excluding tax, discounts, and shipping.
        public let subtotal: Amount
        /// The sum of all exclusive tax amounts (tax collected in addition to the subtotal).
        public let taxExclusive: Amount
        /// The sum of all inclusive tax amounts (tax already included in the subtotal).
        public let taxInclusive: Amount
        /// The sum of all shipping amounts.
        public let shippingRate: Amount
        /// The sum of all discounts. A positive number reduces the amount to be paid.
        public let discount: Amount
        /// The grand total, including discounts and tax.
        public let total: Amount
        /// The amount of customer credit balance applied to the payment.
        ///
        /// A positive number increases the amount to be paid; a negative number decreases it.
        public let appliedBalance: Amount
        /// When `true`, no payment is collected immediately and the amount due is added to
        /// the customer's next invoice. Used for deferred billing of small amounts.
        public let balanceAppliedToNextInvoice: Bool

        public init(
            subtotal: Amount,
            taxExclusive: Amount,
            taxInclusive: Amount,
            shippingRate: Amount,
            discount: Amount,
            total: Amount,
            appliedBalance: Amount,
            balanceAppliedToNextInvoice: Bool
        ) {
            self.subtotal = subtotal
            self.taxExclusive = taxExclusive
            self.taxInclusive = taxInclusive
            self.shippingRate = shippingRate
            self.discount = discount
            self.total = total
            self.appliedBalance = appliedBalance
            self.balanceAppliedToNextInvoice = balanceAppliedToNextInvoice
        }
    }
}
