//
//  PaymentMethod.swift
//  StripePaymentSheet
//
//  Created by Joyce Qin on 7/22/26.
//

extension ExpressCheckoutElement {
    /// A payment method supported by Express Checkout Element.
    enum PaymentMethod: String, Equatable {
        case applePay = "apple_pay"
        case link = "link"
    }
}
