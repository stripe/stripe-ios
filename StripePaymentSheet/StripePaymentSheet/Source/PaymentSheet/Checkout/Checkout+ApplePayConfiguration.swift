//
//  Checkout+ApplePayConfiguration.swift
//  StripePaymentSheet
//
//  Created by Joyce Qin on 7/22/26.
//

import PassKit

/// The merchant identity needed to build an Apple Pay payment request.
///
/// Bridges ``PaymentElement/ApplePayConfiguration`` (Payment Element) and
/// ``ExpressCheckoutElement/ApplePayConfiguration`` (ExpressCheckoutElement) so Apple Pay
/// confirmation code can accept either without caring which surface it came from.
@_spi(STP)
@_spi(ReactNativeSDK)
public protocol CheckoutApplePayConfiguration {
    /// The Apple Pay merchant identifier.
    var merchantId: String { get }

    /// The type of Apple Pay button to display. Defaults to `.plain` when `nil`.
    var buttonType: PKPaymentButtonType? { get }
}

@_spi(STP)
@_spi(ReactNativeSDK)
extension PaymentElement {
    /// Configuration related to Apple Pay
    public struct ApplePayConfiguration: CheckoutApplePayConfiguration {
        /// The Apple Merchant Identifier to use during Apple Pay transactions.
        /// To obtain one, see https://stripe.com/docs/apple-pay#native
        public var merchantId: String

        /// Defines the label that will be displayed in the Apple Pay button.
        /// See <https://developer.apple.com/design/human-interface-guidelines/technologies/apple-pay/buttons-and-marks/>
        /// for all available options.
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
