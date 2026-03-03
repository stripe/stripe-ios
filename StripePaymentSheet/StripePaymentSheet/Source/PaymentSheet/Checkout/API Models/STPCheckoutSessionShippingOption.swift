//
//  STPCheckoutSessionShippingOption.swift
//  StripePayments
//
//  Created by Nick Porter on 3/2/26.
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

import Foundation

/// Represents an available shipping option in a Checkout session.
@_spi(STP) public class STPCheckoutSessionShippingOption {
    /// The shipping rate ID.
    public let id: String
    /// The display name shown to the customer.
    public let displayName: String
    /// The amount in the smallest currency unit.
    public let amount: Int
    /// The three-letter lowercase ISO currency code.
    public let currency: String
    
    init(id: String, displayName: String, amount: Int, currency: String) {
        self.id = id
        self.displayName = displayName
        self.amount = amount
        self.currency = currency
    }
}

// MARK: - Parsing

extension STPCheckoutSessionShippingOption {
    static func shippingOptions(from dict: [AnyHashable: Any], defaultCurrency: String?) -> [STPCheckoutSessionShippingOption] {
        guard let options = dict["shipping_options"] as? [[AnyHashable: Any]] else {
            return []
        }
        return options.compactMap { decode(from: $0, defaultCurrency: defaultCurrency) }
    }

    static func selectedShippingOptionId(from dict: [AnyHashable: Any]) -> String? {
        if let lineItemGroup = dict["line_item_group"] as? [AnyHashable: Any],
           let shippingRate = lineItemGroup["shipping_rate"] as? [AnyHashable: Any],
           let id = shippingRate["id"] as? String {
            return id
        }
        return dict["shipping_rate"] as? String
    }

    static func selectedShippingAmount(from dict: [AnyHashable: Any]) -> Int {
        if let lineItemGroup = dict["line_item_group"] as? [AnyHashable: Any],
           let shippingRate = lineItemGroup["shipping_rate"] as? [AnyHashable: Any],
           let amount = shippingRate["amount"] as? Int {
            return amount
        }
        return 0
    }

    private static func decode(
        from dict: [AnyHashable: Any],
        defaultCurrency: String?
    ) -> STPCheckoutSessionShippingOption? {
        if let shippingRate = dict["shipping_rate"] as? [AnyHashable: Any] {
            guard let id = shippingRate["id"] as? String,
                  let displayName = shippingRate["display_name"] as? String,
                  let amount = shippingRate["amount"] as? Int else {
                return nil
            }
            let currency = (shippingRate["currency"] as? String) ?? defaultCurrency ?? "usd"
            return STPCheckoutSessionShippingOption(
                id: id,
                displayName: displayName,
                amount: amount,
                currency: currency
            )
        }

        if let id = dict["shipping_rate"] as? String {
            return STPCheckoutSessionShippingOption(
                id: id,
                displayName: "Shipping Option",
                amount: 0,
                currency: defaultCurrency ?? "usd"
            )
        }
        return nil
    }
}
