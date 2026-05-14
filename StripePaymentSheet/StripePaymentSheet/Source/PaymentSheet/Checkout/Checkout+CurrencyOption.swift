//
//  Checkout+CurrencyOption.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 5/7/2026.
//

import Foundation

@_spi(STP)
@_spi(ReactNativeSDK)
extension Checkout {
    /// A currency option available on a checkout session when adaptive pricing is active.
    public struct CurrencyOption: Sendable, Hashable {
        /// The total amount in this currency.
        public let amount: Amount
        /// Three-letter ISO 4217 currency code in lowercase.
        public let currency: String
        /// Currency conversion details, present only for the customer's local currency.
        public let currencyConversion: CurrencyConversion?

        public init(
            amount: Amount,
            currency: String,
            currencyConversion: CurrencyConversion? = nil
        ) {
            self.amount = amount
            self.currency = currency
            self.currencyConversion = currencyConversion
        }
    }

    /// Currency conversion details for an adaptive-pricing currency option.
    public struct CurrencyConversion: Sendable, Hashable {
        /// The exchange rate used to convert source currency amounts to customer currency amounts.
        public let fxRate: String
        /// The creation currency of the checkout session before localization
        /// (three-letter ISO 4217 currency code in lowercase).
        public let sourceCurrency: String

        public init(fxRate: String, sourceCurrency: String) {
            self.fxRate = fxRate
            self.sourceCurrency = sourceCurrency
        }
    }
}
