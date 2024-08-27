//
//  ConsumerSession+PaymentMethodType.swift
//  StripePaymentSheet
//
//  Created by Mat Schmid on 2024-08-27.
//

import Foundation

extension ConsumerSession {
    enum PaymentMethodType: String {
        case card = "CARD"
        case bankAccount = "BANK_ACCOUNT"
    }
}
