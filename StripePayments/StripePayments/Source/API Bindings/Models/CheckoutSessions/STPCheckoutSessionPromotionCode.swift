//
//  STPCheckoutSessionPromotionCode.swift
//  StripePayments
//
//  Created by Nick Porter on 2/26/26.
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

import Foundation

/// Represents a promotion code from the Checkout API response.
@_spi(STP) public struct STPCheckoutSessionPromotionCode {
    /// The promotion code string (e.g., "SAVE25").
    public let code: String

    /// The raw API response used to create this object.
    public let allResponseFields: [AnyHashable: Any]

    static func decodedObject(from dict: [AnyHashable: Any]?) -> STPCheckoutSessionPromotionCode? {
        guard let dict = dict,
              let code = dict["code"] as? String else {
            return nil
        }
        return STPCheckoutSessionPromotionCode(
            code: code,
            allResponseFields: dict
        )
    }
}
