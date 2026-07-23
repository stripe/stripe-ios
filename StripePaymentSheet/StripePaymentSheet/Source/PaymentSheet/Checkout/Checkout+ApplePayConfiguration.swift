//
//  Checkout+ApplePayConfiguration.swift
//  StripePaymentSheet
//
//  Created by Joyce Qin on 7/22/26.
//

import PassKit

@_spi(STP)
@_spi(ReactNativeSDK)
extension Checkout {
    /// Configuration for Apple Pay.
    public struct ApplePayConfiguration {
        /// The Apple Pay merchant identifier.
        public let merchantId: String

        /// The type of Apple Pay button to display. Defaults to `.plain` when `nil`.
        public var buttonType: PKPaymentButtonType?

        /// Creates an Apple Pay configuration.
        /// - Parameters:
        ///   - merchantId: The Apple Pay merchant identifier.
        ///   - buttonType: The type of Apple Pay button to display. Defaults to `.plain` when `nil`.
        public init(
            merchantId: String,
            buttonType: PKPaymentButtonType? = nil
        ) {
            self.merchantId = merchantId
            self.buttonType = buttonType
        }
    }
}
