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

        public enum WalletVisibility {
            /// (Default) Show this wallet when Stripe determines it is available for the session.
            case automatic
            /// Always show this wallet if the device supports it, even if the session does not include it.
            case always
            /// Never show this wallet.
            case never
        }

        /// Controls Apple Pay visibility in Express Checkout Element.
        ///
        /// Requires ``Checkout/Configuration/applePayConfiguration`` to be set when not `.never`.
        /// Default: `.automatic`.
        public var applePay: WalletVisibility = .automatic

        /// Controls Link visibility in Express Checkout Element.
        ///
        /// Default: `.automatic`.
        public var link: WalletVisibility = .automatic

        /// Creates a configuration with default values.
        public init() {}
    }
}
