//
//  PaymentElement+LinkConfiguration.swift
//  StripePaymentSheet
//
//  Created by Joyce Qin on 7/22/26.
//

@_spi(STP)
@_spi(ReactNativeSDK)
extension PaymentElement {
    /// Configuration related to Link
    public struct LinkConfiguration {
        /// The Link display mode.
        public var display: Display = .automatic

        /// Creates a Link configuration.
        public init(display: Display = .automatic) {
            self.display = display
        }

        /// Display configuration for Link
        public enum Display: String {
            /// Link will be displayed when available.
            case automatic
            /// Link will never be displayed.
            case never
            /// Link remains enabled (e.g. for automatic Link verification, Instant Bank Payments, Link Card Brand, and inline signup)
            /// but its button/row will not be shown in the payment element UI.
            case walletButtonHidden
        }
    }
}
