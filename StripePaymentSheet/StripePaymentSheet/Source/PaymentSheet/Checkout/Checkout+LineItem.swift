//
//  Checkout+LineItem.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 5/7/2026.
//

import Foundation

@_spi(STP)
@_spi(ReactNativeSDK)
extension Checkout {
    /// A line item in a checkout session.
    public struct LineItem: Sendable, Hashable, Identifiable {
        /// Unique identifier for this line item.
        public let id: String
        /// The item's display name.
        public let name: String
        /// An optional, merchant-supplied description.
        public let description: String?
        /// Image URLs configured on the underlying Product.
        public let images: [String]
        /// The quantity of items being purchased.
        public let quantity: Int
        /// The cost of a single unit of the item.
        public let unitAmount: Amount?
        /// The unit amount with sub-cent precision. Use this instead of ``unitAmount`` when
        /// dealing with sub-cent pricing (for example, usage-based billing).
        public let unitAmountDecimal: DecimalAmount?
        /// Total before any discounts or exclusive taxes are applied.
        public let subtotal: Amount?
        /// Total discount amount. A positive number reduces the amount to be paid.
        public let discount: Amount?
        /// Total amount of exclusive tax (tax collected in addition to the subtotal).
        public let taxExclusive: Amount?
        /// Total amount of inclusive tax (tax already included in the subtotal).
        public let taxInclusive: Amount?
        /// Total amount for this line item, including discounts and tax.
        public let total: Amount?
        /// The discount amounts calculated per discount for this line item.
        public let discountAmounts: [DiscountAmount]
        /// The tax amounts calculated per tax rate for this line item.
        public let taxAmounts: [TaxAmount]
        /// Configuration for this item's quantity to be adjusted by the customer during checkout.
        public let adjustableQuantity: AdjustableQuantity?

        public init(
            id: String,
            name: String,
            description: String? = nil,
            images: [String] = [],
            quantity: Int,
            unitAmount: Amount? = nil,
            unitAmountDecimal: DecimalAmount? = nil,
            subtotal: Amount? = nil,
            discount: Amount? = nil,
            taxExclusive: Amount? = nil,
            taxInclusive: Amount? = nil,
            total: Amount? = nil,
            discountAmounts: [DiscountAmount] = [],
            taxAmounts: [TaxAmount] = [],
            adjustableQuantity: AdjustableQuantity? = nil
        ) {
            self.id = id
            self.name = name
            self.description = description
            self.images = images
            self.quantity = quantity
            self.unitAmount = unitAmount
            self.unitAmountDecimal = unitAmountDecimal
            self.subtotal = subtotal
            self.discount = discount
            self.taxExclusive = taxExclusive
            self.taxInclusive = taxInclusive
            self.total = total
            self.discountAmounts = discountAmounts
            self.taxAmounts = taxAmounts
            self.adjustableQuantity = adjustableQuantity
        }
    }

    /// Configuration for a customer-adjustable line item quantity.
    public struct AdjustableQuantity: Sendable, Hashable {
        /// The minimum quantity the customer can purchase.
        public let minimum: Int
        /// The maximum quantity the customer can purchase.
        public let maximum: Int

        public init(minimum: Int, maximum: Int) {
            self.minimum = minimum
            self.maximum = maximum
        }
    }
}
