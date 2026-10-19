//
//  CheckoutSessionUpdate.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 2/25/26.
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

import Foundation

@_spi(STP)
extension CheckoutController {
    enum SessionUpdate {
        case setPromotionCode(String)
        case setTaxRegion(Address?)
        case setCurrency(String)

        var parameters: [String: Any] {
            switch self {
            case .setPromotionCode(let code):
                return ["promotion_code": code]
            case .setTaxRegion(let address):
                guard let address else {
                    return ["tax_region": ""]
                }
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
            }
        }
    }
}
