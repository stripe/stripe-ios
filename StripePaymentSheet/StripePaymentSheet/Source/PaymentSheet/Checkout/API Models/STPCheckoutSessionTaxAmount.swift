//
//  STPCheckoutSessionTaxAmount.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 3/5/26.
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

import Foundation

/// Tax amounts applied to a CheckoutSession.
@_spi(STP) public class STPCheckoutSessionTaxAmount: Hashable, Equatable {
    /// The amount of tax.
    public let amount: Int
    /// Whether this tax amount is inclusive.
    public let inclusive: Bool
    /// The taxable amount.
    public let taxableAmount: Int
    /// The tax rate.
    public let taxRate: STPCheckoutSessionTaxRate?

    init(amount: Int, inclusive: Bool, taxableAmount: Int, taxRate: STPCheckoutSessionTaxRate?) {
        self.amount = amount
        self.inclusive = inclusive
        self.taxableAmount = taxableAmount
        self.taxRate = taxRate
    }

    static func taxAmounts(from dict: [AnyHashable: Any]?) -> [STPCheckoutSessionTaxAmount] {
        guard let lineItemGroup = dict?["line_item_group"] as? [AnyHashable: Any],
              let taxAmounts = lineItemGroup["tax_amounts"] as? [[AnyHashable: Any]] else {
            return []
        }
        return taxAmounts.compactMap { decode(from: $0) }
    }

    private static func decode(from dict: [AnyHashable: Any]) -> STPCheckoutSessionTaxAmount? {
        guard let amount = dict["amount"] as? Int,
              let inclusive = dict["inclusive"] as? Bool,
              let taxableAmount = dict["taxable_amount"] as? Int else {
            return nil
        }

        let taxRate = STPCheckoutSessionTaxRate.decode(from: dict["tax_rate"] as? [AnyHashable: Any])

        return STPCheckoutSessionTaxAmount(
            amount: amount,
            inclusive: inclusive,
            taxableAmount: taxableAmount,
            taxRate: taxRate
        )
    }

    public static func == (lhs: STPCheckoutSessionTaxAmount, rhs: STPCheckoutSessionTaxAmount) -> Bool {
        return lhs.amount == rhs.amount &&
               lhs.inclusive == rhs.inclusive &&
               lhs.taxableAmount == rhs.taxableAmount &&
               lhs.taxRate == rhs.taxRate
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(amount)
        hasher.combine(inclusive)
        hasher.combine(taxableAmount)
        hasher.combine(taxRate)
    }
}

/// A tax rate applied to a CheckoutSession.
@_spi(STP) public class STPCheckoutSessionTaxRate: Hashable, Equatable {
    /// The display name of the tax rate.
    public let displayName: String?
    /// The percentage of the tax rate.
    public let percentage: Double
    /// The state/jurisdiction of the tax rate.
    public let jurisdiction: String?

    init(displayName: String?, percentage: Double, jurisdiction: String?) {
        self.displayName = displayName
        self.percentage = percentage
        self.jurisdiction = jurisdiction
    }

    static func decode(from dict: [AnyHashable: Any]?) -> STPCheckoutSessionTaxRate? {
        guard let dict = dict,
              let percentage = dict["percentage"] as? Double else {
            return nil
        }
        return STPCheckoutSessionTaxRate(
            displayName: dict["display_name"] as? String,
            percentage: percentage,
            jurisdiction: dict["jurisdiction"] as? String
        )
    }

    public static func == (lhs: STPCheckoutSessionTaxRate, rhs: STPCheckoutSessionTaxRate) -> Bool {
        return lhs.displayName == rhs.displayName &&
               lhs.percentage == rhs.percentage &&
               lhs.jurisdiction == rhs.jurisdiction
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(displayName)
        hasher.combine(percentage)
        hasher.combine(jurisdiction)
    }
}
