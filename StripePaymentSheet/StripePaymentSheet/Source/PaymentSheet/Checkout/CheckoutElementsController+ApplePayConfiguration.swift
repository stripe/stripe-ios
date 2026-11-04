//
//  CheckoutElementsController+ApplePayConfiguration.swift
//  StripePaymentSheet
//
//  Created by Joyce Qin on 7/22/26.
//

import PassKit

/// Bridges ``PaymentElement/ApplePayConfiguration`` (Payment Element) and
/// ``ExpressCheckoutElement/ApplePayConfiguration`` (ExpressCheckoutElement) so Apple Pay
/// confirmation code can accept either without caring which surface it came from.
@_spi(InternalOnlyAPI)
@_spi(ReactNativeSDK)
public protocol CheckoutApplePayConfiguration {
    /// The type of Apple Pay button to display. 
    var buttonType: PKPaymentButtonType? { get }
}
