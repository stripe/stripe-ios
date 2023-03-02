//
//  STPPaymentMethod+PaymentSheet.swift
//  StripePaymentSheet
//
//  Created by David Estes on 6/30/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
@_spi(STP) import StripePaymentsUI

extension STPPaymentMethod {
    var paymentSheetLabel: String {
        switch type {
        case .card:
            return "••••\(card?.last4 ?? "")"
        case .SEPADebit:
            return "••••\(sepaDebit?.last4 ?? "")"
        case .USBankAccount:
            return "••••\(usBankAccount?.last4 ?? "")"
        default:
            return type.displayName
        }
    }

    var paymentSheetAccessibilityLabel: String? {
        switch type {
        case .card:
            guard let card = self.card else {
                return nil
            }
            let brand = STPCardBrandUtilities.stringFrom(card.brand) ?? ""
            let last4 = card.last4 ?? ""
            let last4Spaced = last4.map { String($0) }.joined(separator: " ")
            let localized = String.Localized.card_brand_ending_in_last_4
            return String(format: localized, brand, last4Spaced)
        case .USBankAccount:
            guard let usBankAccount = self.usBankAccount else {
                return nil
            }
            return String(format: String.Localized.bank_name_account_ending_in_last_4, usBankAccount.bankName, usBankAccount.last4)
        default:
            return nil
        }

    }
}
