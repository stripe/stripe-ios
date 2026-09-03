//
//  PaymentElement+LinkConfiguration.swift
//  StripePaymentSheet
//
//  Created by Joyce Qin on 7/22/26.
//

@_spi(STP)
@_spi(ReactNativeSDK)
extension PaymentElement {
    /// Configuration for Link.
    public struct LinkConfiguration {
        /// Controls whether Link is displayed.
        public var display: Display = .automatic

        /// Creates a Link configuration.
        public init(display: Display = .automatic) {
            self.display = display
        }

        /// Controls whether Link is displayed.
        public enum Display: String {
            /// Show Link when it is available.
            case automatic
            /// Never show Link.
            case never
            /// Keep Link enabled, but hide its button or row in PaymentElement.
            case walletButtonHidden
        }
    }
}
