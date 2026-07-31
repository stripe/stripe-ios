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
        /// Called when a payment confirmation attempt completes.
        ///
        /// Receives a ``Checkout/ConfirmResult`` describing whether the payment
        /// succeeded, was canceled by the user, or failed with an error.
        public var confirmHandler: ((Checkout.ConfirmResult) -> Void)?

        /// Creates a configuration with default values.
        public init() {}
    }
}
