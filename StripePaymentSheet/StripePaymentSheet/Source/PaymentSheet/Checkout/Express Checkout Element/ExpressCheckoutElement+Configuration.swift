//
//  ExpressCheckoutElement+Configuration.swift
//  StripePaymentSheet
//
//  Created by Joyce Qin on 7/22/26.
//

@_spi(STP)
@_spi(ReactNativeSDK)
extension ExpressCheckoutElement {
    /// Configuration options for ``ExpressCheckoutElement``.
    public struct Configuration {
        /// Called after an Apple Pay payment attempt completes.
        ///
        /// Use this to react to the Apple Pay result, for example by navigating to a
        /// confirmation screen or displaying an error message.
        ///
        /// This handler is only invoked when the customer taps the Apple Pay button in the
        /// ``ExpressCheckoutElement`` UI. It is **not** called when ``Checkout/confirm(from:)``
        /// is used directly.
        public var applePayConfirmHandler: ((Checkout.ConfirmResult) -> Void)?

        /// Creates a configuration with default values.
        public init() {}
    }
}
