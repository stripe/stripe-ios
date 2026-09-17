//
//  PaymentMethod.swift
//  StripePaymentSheet
//
//  Created by Joyce Qin on 7/22/26.
//

extension ExpressCheckoutElement {
    enum PaymentMethod: String, Equatable {
        case applePay = "apple_pay"
        case link = "link"
    }
}
