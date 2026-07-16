//
//  CheckoutSessionUpdate.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 2/25/26.
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeCore

@_spi(STP)
extension Checkout {
    enum SessionUpdate {
        case setPromotionCode(String)
        case setLineItemQuantity(lineItemId: String, quantity: Int)
        case setShippingRate(String)
        case setTaxRegion(Address)
        case setCurrency(String)
        case updatePaymentMethod(id: String, billing: PaymentMethodBillingDetails?, expiry: PaymentMethodExpiryDetails?)

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
            case .setCurrency(let currency):
                return ["updated_currency": currency]
            case .updatePaymentMethod(let id, let billing, let expiry):
                return STPAPIClient.updatePaymentMethodParameters(
                    paymentMethodId: id,
                    billingDetails: billing,
                    expiryDetails: expiry
                )
            }
        }
    }
}
