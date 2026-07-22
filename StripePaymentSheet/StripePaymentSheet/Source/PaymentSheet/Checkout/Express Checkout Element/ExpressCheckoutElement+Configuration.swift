//
//  ExpressCheckoutElement+Configuration.swift
//  StripePaymentSheet
//
//  Created by Joyce Qin on 7/21/26.
//

extension ExpressCheckoutElement {
    public struct Configuration {
        public enum WalletVisibility {
            case automatic
            case never
        }

        /// Controls whether Apple Pay is shown. Defaults to `.automatic`.
        public var applePayVisibility: WalletVisibility = .automatic

        /// Controls whether Link is shown. Defaults to `.automatic`.
        public var linkVisibility: WalletVisibility = .automatic

        public init() {}
    }
}
