//
//  STPCheckoutSessionLineItem.swift
//  StripePayments
//
//  Created by Nick Porter on 3/2/26.
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

import Foundation

/// Represents a line item in a Checkout session.
@_spi(STP) public struct STPCheckoutSessionLineItem {
    /// The line item ID.
    public let id: String
    /// The display name for the line item.
    public let name: String
    /// The selected quantity for this line item.
    public let quantity: Int
    /// The per-unit amount in the smallest currency unit.
    public let amount: Int
    /// The three-letter lowercase ISO currency code.
    public let currency: String
}

// MARK: - Parsing

extension STPCheckoutSessionLineItem {
    static func lineItems(from dict: [AnyHashable: Any], defaultCurrency: String?) -> [STPCheckoutSessionLineItem] {
        guard let lineItemGroup = dict["line_item_group"] as? [AnyHashable: Any],
              let lineItems = lineItemGroup["line_items"] as? [[AnyHashable: Any]] else {
            return []
        }
        return lineItems.compactMap { decode(from: $0, defaultCurrency: defaultCurrency) }
    }

    private static func decode(
        from dict: [AnyHashable: Any],
        defaultCurrency: String?
    ) -> STPCheckoutSessionLineItem? {
        guard let id = dict["id"] as? String,
              let quantity = dict["quantity"] as? Int,
              let name = dict["name"] as? String else {
            return nil
        }

        let price = dict["price"] as? [AnyHashable: Any]
        let amount = (price?["unit_amount"] as? Int) ?? 0
        let currency = (price?["currency"] as? String) ?? defaultCurrency ?? "usd"

        return STPCheckoutSessionLineItem(
            id: id,
            name: name,
            quantity: quantity,
            amount: amount,
            currency: currency
        )
    }
}
