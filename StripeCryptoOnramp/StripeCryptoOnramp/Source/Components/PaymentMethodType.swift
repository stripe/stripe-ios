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
public enum PaymentMethodType: Equatable {

    /// Limits payment options in Stripe's wallet UI to cards, such as a credit or debit card.
    case card

    /// Limits payment options in Stripe's wallet UI to bank accounts.
    case bankAccount
    
    /// Does not limit to cards or bank accounts, either can be selected in Stripe's wallet UI.
    case cardAndBankAccount
    
    /// Proceeds to collect payment via Apple Pay, skipping Stripe's wallet UI.
    /// Requires a `PKPaymentRequest` containing details about the payment.
    case applePay(paymentRequest: PKPaymentRequest)
}

extension PaymentMethodType {
    var linkPaymentMethodType: [LinkPaymentMethodType]? {
        switch self {
        case .card:
            [.card]
        case .bankAccount:
            [.bankAccount]
        case .cardAndBankAccount:
            [.card, .bankAccount]
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
        case .cardAndBankAccount:
            return "card_and_bank_account"
        case .applePay:
            return "apple_pay"
        }
    }
}
