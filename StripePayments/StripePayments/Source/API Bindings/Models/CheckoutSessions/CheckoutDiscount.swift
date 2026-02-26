//
//  CheckoutDiscount.swift
//  StripePayments
//
//  Created by Nick Porter on 2/25/26.
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

import Foundation

/// Represents a discount applied to a Checkout session.
@_spi(STP) public struct CheckoutDiscount: Equatable, Sendable {
    /// The unique identifier for this discount.
    public let id: String

    /// The name of the discount.
    public let name: String?

    /// The promotion code, if this discount was applied via promotion code.
    public let promotionCode: String?

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
        promotionCode: String? = nil,
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
