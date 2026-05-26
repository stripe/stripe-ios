//
//  Checkout+Discount.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 5/7/2026.
//

import Foundation

@_spi(STP)
@_spi(ReactNativeSDK)
extension Checkout {
    /// A discount applied to a checkout session or line item.
    public struct DiscountAmount: Sendable, Hashable {
        /// The discount amount. A positive number reduces the amount to be paid.
        public let amount: Amount
        /// A user-facing description of the discount.
        public let displayName: String
        /// The customer-facing promotion code used to apply this discount, if any.
        public let promotionCode: String?

        public init(amount: Amount, displayName: String, promotionCode: String? = nil) {
            self.amount = amount
            self.displayName = displayName
            self.promotionCode = promotionCode
        }
    }
}
