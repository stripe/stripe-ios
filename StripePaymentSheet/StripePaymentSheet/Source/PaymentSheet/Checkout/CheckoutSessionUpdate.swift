//
//  CheckoutSessionUpdate.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 2/25/26.
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

import Foundation

@_spi(CheckoutSessionsPreview)
extension Checkout {
    enum SessionUpdate {
        case setPromotionCode(String)
        case setLineItemQuantity(lineItemId: String, quantity: Int)
        case setShippingRate(String)
        case setTaxRegion(Address)
        case setTaxId(type: String, value: String)
        case setCurrency(String)

        var parameters: [String: Any] {
            switch self {
            case .setPromotionCode(let code):
                return ["promotion_code": code]
            case .setLineItemQuantity(let lineItemId, let quantity):
                return [
                    "updated_line_item_quantity[line_item_id]": lineItemId,
                    "updated_line_item_quantity[quantity]": quantity,
                ]
            case .setShippingRate(let optionId):
                return ["shipping_rate": optionId]
            case .setTaxRegion(let address):
                return ([
                    "tax_region[country]": address.country,
                    "tax_region[line1]": address.line1,
                    "tax_region[line2]": address.line2,
                    "tax_region[city]": address.city,
                    "tax_region[state]": address.state,
                    "tax_region[postal_code]": address.postalCode,
                ] as [String: Any?]).compactMapValues { $0 }
            case .setTaxId(let type, let value):
                return [
                    "tax_id_collection[tax_id][type]": type,
                    "tax_id_collection[tax_id][value]": value,
                ]
            case .setCurrency(let currency):
                return ["updated_currency": currency]
            }
        }
    }
}
