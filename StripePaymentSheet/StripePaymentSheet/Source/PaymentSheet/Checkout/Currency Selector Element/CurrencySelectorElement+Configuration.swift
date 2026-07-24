//
//  CurrencySelectorElement+Configuration.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 7/22/26.
//

@_spi(STP)
@_spi(ReactNativeSDK)
extension CurrencySelectorElement {
    /// Configuration for ``CurrencySelectorElement``.
    public struct Configuration {
        // MARK: - Public

        /// Creates a configuration with default values.
        public init() {}

        /// Describes the appearance of the currency selector.
        public var appearance: Appearance = .init()
    }
}
