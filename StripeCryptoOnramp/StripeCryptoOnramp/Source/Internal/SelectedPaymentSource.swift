//
//  SelectedPaymentSource.swift
//  StripeCryptoOnramp
//
//  Created by Michael Liberatore on 8/18/25.
//

import Foundation
@_spi(STP) import StripePayments

/// Represents the possible selected payment method types.
enum SelectedPaymentSource {

    /// Payment method was selected via Link UI, either credit/debit card or bank account.
    case link

    /// Apple Pay was selected as the payment method.
    case applePay(StripeAPI.PaymentMethod)

    var analyticsValue: String {
        switch self {
        case .link:
            return "link" // Generic for Link since we can't differentiate card vs bank account here
        case .applePay:
            return "apple_pay"
        }
    }
}
