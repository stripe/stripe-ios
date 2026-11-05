//
//  PaymentMethod.swift
//  StripePaymentSheet
//
//  Created by Joyce Qin on 7/22/26.
//

@_spi(InternalOnlyAPI)
@_spi(ReactNativeSDK)
extension ExpressCheckoutElement {
    /// A payment method supported by Express Checkout Element.
    public enum PaymentMethod: String, Equatable {
        case applePay = "apple_pay"
        case link = "link"
    }
}
