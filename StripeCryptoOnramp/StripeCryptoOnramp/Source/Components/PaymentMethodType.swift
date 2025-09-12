//
//  PaymentMethodType.swift
//  StripeCryptoOnramp
//
//  Created by Michael Liberatore on 8/18/25.
//

import PassKit
@_spi(STP) import StripePaymentSheet

/// Represents possible payment types that can be collected for checkout.
@_spi(STP)
public enum PaymentMethodType {

    /// Card-based payment, such as a credit or debit card.
    case card

    /// Bank account-based payment.
    case bankAccount

    /// Apple Pay payment. Requires a `PKPaymentRequest` containing details about the payment.
    case applePay(paymentRequest: PKPaymentRequest)
}

extension PaymentMethodType {
    var linkPaymentMethodType: LinkPaymentMethodType? {
        switch self {
        case .card:
            .card
        case .bankAccount:
            .bankAccount
        case .applePay:
            nil
        }
    }

    var analyticsValue: String {
        switch self {
        case .card:
            return "card"
        case .bankAccount:
            return "bank_account"
        case .applePay:
            return "apple_pay"
        }
    }
}
