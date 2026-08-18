//
//  Checkout+Session+DiscountAmount.swift
//  StripePaymentSheet
//
//  Created by Yuki Tokuhiro on 8/16/26.
//

import Foundation

@_spi(STP)
@_spi(ReactNativeSDK)
extension Checkout.Session {
    /// An aggregate discount amount calculated across all line items in a Checkout Session.
    public struct DiscountAmount: Sendable, Hashable {
        /// The localized, formatted representation of the discount amount.
        public let amount: String

        /// The numeric, unformatted representation of the discount amount in minor units.
        public let minorUnitsAmount: Double

        /// A user-facing description of the discount.
        public let displayName: String

        /// The customer-facing promotion code used to apply this discount, if any.
        public let promotionCode: String?

        /// The percentage discounted, if this is a percentage-based discount.
        public let percentOff: Double?

        public init(
            amount: String,
            minorUnitsAmount: Double,
            displayName: String,
            promotionCode: String? = nil,
            percentOff: Double? = nil
        ) {
            self.amount = amount
            self.minorUnitsAmount = minorUnitsAmount
            self.displayName = displayName
            self.promotionCode = promotionCode
            self.percentOff = percentOff
        }
    }
}
