//
//  SelectedPaymentSource.swift
//  StripeCryptoOnramp
//
//  Created by Michael Liberatore on 8/18/25.
//

import Foundation
@_spi(STP) import StripePayments

/// An Apple Pay selection and the immutable publishable key used to create it.
struct ApplePayPaymentSource {
    let paymentMethod: StripeAPI.PaymentMethod
    let kycInfo: KycInfo?
    let platformPublishableKey: String
    /// True when Apple Pay collection began before authentication.
    /// Requires a fresh publishable-key comparison before every token attempt.
    let requiresPublishableKeyRevalidation: Bool
}

/// Represents the possible selected payment method types.
enum SelectedPaymentSource {

    /// Payment method was selected via Link UI, either credit/debit card or bank account.
    case link

    /// Apple Pay was selected as the payment method.
    case applePay(ApplePayPaymentSource)

    var analyticsValue: String {
        switch self {
        case .link:
            return "link"
        case .applePay:
            return "apple_pay"
        }
    }
}
