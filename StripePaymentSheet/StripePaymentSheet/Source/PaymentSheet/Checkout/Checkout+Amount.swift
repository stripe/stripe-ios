//
//  Checkout+Amount.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 5/7/2026.
//

import Foundation

@_spi(STP)
@_spi(ReactNativeSDK)
extension Checkout {
    /// A monetary amount with both a localized display string and a value in the
    /// smallest currency unit (e.g. cents).
    public struct Amount: Sendable, Hashable {
        /// A localized, formatted string representation including currency symbols (e.g. `"$10.00"`).
        public let amount: String
        /// The amount in the smallest currency unit
        /// (e.g. `1000` for `$10.00`, or `100` for `¥100` since JPY is zero-decimal).
        public let minorUnitsAmount: Int

        public init(amount: String, minorUnitsAmount: Int) {
            self.amount = amount
            self.minorUnitsAmount = minorUnitsAmount
        }
    }

    /// A monetary amount supporting sub-minor-unit precision.
    ///
    /// Use this for sub-cent pricing (for example, usage-based billing) where rounding to
    /// the nearest minor unit would lose precision.
    public struct DecimalAmount: Sendable, Hashable {
        /// A localized, formatted string representation including currency symbols.
        public let amount: String
        /// The amount in the smallest currency unit, supporting decimal precision
        /// (for example, `0.5` for half a cent).
        public let minorUnitsAmount: Decimal

        public init(amount: String, minorUnitsAmount: Decimal) {
            self.amount = amount
            self.minorUnitsAmount = minorUnitsAmount
        }
    }
}
