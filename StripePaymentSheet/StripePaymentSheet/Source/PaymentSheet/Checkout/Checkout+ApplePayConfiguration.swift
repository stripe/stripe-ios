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
