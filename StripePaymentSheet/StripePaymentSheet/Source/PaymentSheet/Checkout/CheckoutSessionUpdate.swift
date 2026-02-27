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
            }
        }
    }
}
