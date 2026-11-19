//
//  CurrencySelectorElement+Configuration.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 7/22/26.
//

@_spi(ReactNativeSDK)
@_spi(CheckoutSessionsPreview)
extension CurrencySelectorElement {
    /// Configuration for Currency Selector Element.
    public struct Configuration {
        /// The appearance of Currency Selector Element.
        public var appearance: Appearance = .init()

        public init() {}
    }
}
