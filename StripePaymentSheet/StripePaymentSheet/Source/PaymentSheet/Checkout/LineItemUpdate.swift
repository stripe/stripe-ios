//
//  LineItemUpdate.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 2/25/26.
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

import Foundation

@_spi(CheckoutSessionsPreview)
extension Checkout {
    /// Parameters for updating a line item's quantity.
    public struct LineItemUpdate {
        public let lineItemId: String
        public let quantity: Int

        public init(lineItemId: String, quantity: Int) {
            self.lineItemId = lineItemId
            self.quantity = quantity
        }
    }
}
