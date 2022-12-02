//
//  STPKlarnaLineItem.swift
//  StripePayments
//
//  Created by David Estes on 11/19/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

import Foundation

/// The type of the Klarna line item.
@objc public enum STPKlarnaLineItemType: Int {
    /// The line item for a product
    case SKU
    /// The line item for taxes
    case tax
    /// The line item for shipping costs
    case shipping
}

/// An object representing a line item in a Klarna source.
/// - seealso: https://stripe.com/docs/sources/klarna#create-source
public class STPKlarnaLineItem: NSObject {
    /// The line item's type. One of `sku` (for a product), `tax` (for taxes), or `shipping` (for shipping costs).
    @objc public var itemType: STPKlarnaLineItemType
    /// The human-readable description for the line item.
    @objc public var itemDescription: String
    /// The quantity to display for this line item.
    @objc public var quantity: NSNumber
    /// The total price of this line item.
    /// Note: This is the total price after multiplying by the quantity, not
    /// the price of an individual item. It is denominated in the currency
    /// of the STPSourceParams which contains it.
    @objc public var totalAmount: NSNumber

    /// Initialize this `STPKlarnaLineItem` with a set of parameters.
    /// - Parameters:
    ///   - itemType:         The line item's type.
    ///   - itemDescription:  The human-readable description for the line item.
    ///   - quantity:         The quantity to display for this line item.
    ///   - totalAmount:      The total price of this line item.
    @objc
    public init(
        itemType: STPKlarnaLineItemType,
        itemDescription: String,
        quantity: NSNumber,
        totalAmount: NSNumber
    ) {
        self.itemType = itemType
        self.itemDescription = itemDescription
        self.quantity = quantity
        self.totalAmount = totalAmount
    }
}
