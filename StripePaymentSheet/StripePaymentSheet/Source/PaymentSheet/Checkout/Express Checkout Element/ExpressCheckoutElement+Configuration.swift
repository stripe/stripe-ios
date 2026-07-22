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
        /// Controls whether a wallet button (Apple Pay or Link) is shown.
        public enum WalletVisibility {
            /// Show the button when the wallet is available and the session supports it.
            case automatic
            /// Never show the button, regardless of availability.
            case never
        }

        /// Controls Apple Pay button visibility. Defaults to `.automatic`.
        public var applePayVisibility: WalletVisibility = .automatic

        /// Controls Link button visibility. Defaults to `.automatic`.
        public var linkVisibility: WalletVisibility = .automatic

        /// Creates a configuration with default values.
        public init() {}
    }
}
