//
//  Checkout+ShippingOption.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 5/7/2026.
//

import Foundation

@_spi(STP)
@_spi(ReactNativeSDK)
extension Checkout {
    /// A shipping option available in a checkout session.
    public struct ShippingOption: Sendable, Hashable, Identifiable {
        /// The shipping rate ID.
        public let id: String
        /// A user-facing description of the shipping option.
        public let displayName: String?
        /// The shipping cost.
        public let amount: Amount
        /// Three-letter ISO 4217 currency code in lowercase.
        public let currency: String
        /// The estimated range for how long shipping will take.
        public let deliveryEstimate: DeliveryEstimate?

        public init(
            id: String,
            displayName: String?,
            amount: Amount,
            currency: String,
            deliveryEstimate: DeliveryEstimate? = nil
        ) {
            self.id = id
            self.displayName = displayName
            self.amount = amount
            self.currency = currency
            self.deliveryEstimate = deliveryEstimate
        }
    }

    /// The estimated delivery range for a shipping option.
    public struct DeliveryEstimate: Sendable, Hashable {
        /// A bound (minimum or maximum) of a delivery estimate.
        public struct Bound: Sendable, Hashable {
            /// The unit of time for a delivery estimate.
            public enum Unit: Sendable, Hashable {
                case unknown
                case hour
                case day
                case businessDay
                case week
                case month
            }

            /// The unit of time.
            public let unit: Unit
            /// The number of units.
            public let value: Int

            public init(unit: Unit, value: Int) {
                self.unit = unit
                self.value = value
            }
        }

        /// The lower bound of the delivery estimate.
        public let minimum: Bound?
        /// The upper bound of the delivery estimate.
        public let maximum: Bound?

        public init(minimum: Bound?, maximum: Bound?) {
            self.minimum = minimum
            self.maximum = maximum
        }
    }

    /// The shipping option selected for a checkout session, plus any computed shipping tax.
    public struct SelectedShipping: Sendable, Hashable {
        /// The selected shipping option.
        public let shippingOption: ShippingOption
        /// Tax amounts calculated for the shipping cost.
        public let taxAmounts: [TaxAmount]

        public init(shippingOption: ShippingOption, taxAmounts: [TaxAmount] = []) {
            self.shippingOption = shippingOption
            self.taxAmounts = taxAmounts
        }
    }
}
