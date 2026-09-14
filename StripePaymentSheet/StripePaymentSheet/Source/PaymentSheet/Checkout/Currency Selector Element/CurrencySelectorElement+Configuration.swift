//
//  CurrencySelectorElement+Configuration.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 7/22/26.
//

@_spi(STP)
@_spi(ReactNativeSDK)
extension CurrencySelectorElement {
    /// Configuration for Currency Selector Element.
    public struct Configuration {
        /// The appearance of Currency Selector Element.
        public var appearance: Appearance = .init()

        public init() {}
    }
}
