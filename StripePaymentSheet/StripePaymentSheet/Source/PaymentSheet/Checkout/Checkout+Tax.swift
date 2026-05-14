//
//  Checkout+Tax.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 5/7/2026.
//

import Foundation

@_spi(STP)
@_spi(ReactNativeSDK)
extension Checkout {
    /// Tax computation status and aggregated tax amounts for a checkout session.
    public struct Tax: Sendable, Hashable {
        /// The current tax computation status.
        public let status: TaxStatus
        /// The aggregate amounts calculated per tax rate for all line items, or `nil`
        /// if tax has not yet been computed (i.e. the customer's address has not been collected).
        public let taxAmounts: [TaxAmount]?

        public init(status: TaxStatus, taxAmounts: [TaxAmount]?) {
            self.status = status
            self.taxAmounts = taxAmounts
        }
    }

    /// The tax computation status of a checkout session.
    public enum TaxStatus: Sendable, Hashable {
        /// A status not recognized by this version of the SDK.
        case unknown
        /// The final tax amount is computed and the session is ready for confirmation.
        case ready
        /// A shipping address must be provided to calculate tax.
        case requiresShippingAddress
        /// A billing address must be provided to calculate tax.
        case requiresBillingAddress
    }

    /// A tax amount calculated for a line item, shipping option, or aggregate session total.
    public struct TaxAmount: Sendable, Hashable {
        /// The tax amount.
        public let amount: Amount
        /// Whether this tax amount is inclusive (already included in the subtotal) or
        /// exclusive (collected in addition to the subtotal).
        public let inclusive: Bool
        /// A user-facing description of the tax (e.g. `"Sales Tax"` or `"VAT 20%"`).
        public let displayName: String

        public init(amount: Amount, inclusive: Bool, displayName: String) {
            self.amount = amount
            self.inclusive = inclusive
            self.displayName = displayName
        }
    }
}
