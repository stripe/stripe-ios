//
//  STPCheckoutSessionTaxAmount.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 3/5/26.
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

import Foundation

/// Tax amounts applied to a CheckoutSession.
@_spi(STP) public struct STPCheckoutSessionTaxAmount: Hashable {
    /// The amount of tax.
    public let amount: Int
    /// Whether this tax amount is inclusive.
    public let inclusive: Bool
    /// The tax rate.
    public let taxRate: STPCheckoutSessionTaxRate?

    /// The taxable amount (internal use only).
    let taxableAmount: Int

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
}

/// A tax rate applied to a CheckoutSession.
@_spi(STP) public struct STPCheckoutSessionTaxRate: Hashable {
    /// The display name of the tax rate.
    public let displayName: String?
    /// The percentage of the tax rate.
    public let percentage: Double
    /// The state/jurisdiction of the tax rate.
    public let jurisdiction: String?

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
}

// MARK: - Convenience Properties

extension STPCheckoutSessionTaxRate {
    /// A formatted percentage string, e.g. "8.25%".
    public var formattedPercentage: String {
        String(format: "%g%%", percentage)
    }

    /// A human-readable description combining jurisdiction and rate, e.g. "CA 8.25%" or "8.25%".
    public var rateDescription: String {
        [jurisdiction, formattedPercentage].compactMap { $0 }.joined(separator: " ")
    }
}
