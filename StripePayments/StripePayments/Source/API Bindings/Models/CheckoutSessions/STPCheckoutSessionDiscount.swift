//
//  STPCheckoutSessionDiscount.swift
//  StripePayments
//
//  Created by Nick Porter on 2/25/26.
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

import Foundation

/// Represents a discount applied to a Checkout session.
@_spi(STP) public struct STPCheckoutSessionDiscount {
    /// A synthetic identifier for this discount (e.g., "discount_0").
    public let id: String

    /// The name of the discount.
    public let name: String?

    /// The promotion code, if this discount was applied via promotion code.
    public let promotionCode: STPCheckoutSessionPromotionCode?

    /// The discount amount in the smallest currency unit (e.g., cents).
    public let amount: Int

    /// The percentage off, if this is a percentage-based discount.
    public let percentOff: Double?

    /// The fixed amount off, if this is a fixed-amount discount.
    public let amountOff: Int?

    /// Creates a new discount.
    public init(
        id: String,
        name: String? = nil,
        promotionCode: STPCheckoutSessionPromotionCode? = nil,
        amount: Int,
        percentOff: Double? = nil,
        amountOff: Int? = nil
    ) {
        self.id = id
        self.name = name
        self.promotionCode = promotionCode
        self.amount = amount
        self.percentOff = percentOff
        self.amountOff = amountOff
    }
}

// MARK: - Parsing

extension STPCheckoutSessionDiscount {

    /// Parses discounts from a session response dictionary.
    /// Reads from `line_item_group.discount_amounts`.
    static func discounts(from dict: [AnyHashable: Any]) -> [STPCheckoutSessionDiscount] {
        let lineItemGroup = dict["line_item_group"] as? [AnyHashable: Any]
        let discountAmounts = lineItemGroup?["discount_amounts"] as? [[AnyHashable: Any]] ?? []
        return discountAmounts.enumerated().compactMap { index, discount in
            decode(from: discount, id: "discount_\(index)")
        }
    }

    /// Parses a single discount from a `discount_amounts` entry.
    private static func decode(from dict: [AnyHashable: Any], id: String) -> STPCheckoutSessionDiscount? {
        let couponDict = dict["coupon"] as? [AnyHashable: Any]
        let promotionCodeDict = dict["promotion_code"] as? [AnyHashable: Any]
        let amount = dict["amount"] as? Int ?? 0
        guard amount > 0 else { return nil }
        return STPCheckoutSessionDiscount(
            id: id,
            name: couponDict?["name"] as? String,
            promotionCode: STPCheckoutSessionPromotionCode.decodedObject(from: promotionCodeDict),
            amount: amount,
            percentOff: couponDict?["percent_off"] as? Double,
            amountOff: couponDict?["amount_off"] as? Int
        )
    }
}
