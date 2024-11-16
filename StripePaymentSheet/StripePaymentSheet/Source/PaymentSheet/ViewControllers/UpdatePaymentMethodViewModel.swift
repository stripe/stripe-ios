//
//  UpdatePaymentMethodViewModel.swift
//  StripePaymentSheet
//
//  Created by Joyce Qin on 11/15/24.
//

import Foundation
@_spi(STP) import StripeCore
import UIKit

class UpdatePaymentMethodViewModel {
    let paymentMethodType: STPPaymentMethodType
    let supportedPaymentMethods: [STPPaymentMethodType] = [.card, .USBankAccount, .SEPADebit]
    let canEdit: Bool
    let canRemove: Bool
    lazy var header: String = {
        switch paymentMethodType {
        case .card:
            return .Localized.manage_card
        case .USBankAccount:
            return .Localized.manage_us_bank_account
        case .SEPADebit:
            return .Localized.manage_sepa_debit
        default:
            fatalError("Updating payment method has not been implemented for \(paymentMethodType)")
        }
    }()
    lazy var detailsCannotBeChanged: String = {
        switch paymentMethodType {
        case .card:
            return .Localized.card_details_cannot_be_changed
        case .USBankAccount:
            return .Localized.bank_account_details_cannot_be_changed
        case .SEPADebit:
            return .Localized.sepa_debit_details_cannot_be_changed
        default:
            fatalError("Updating payment method has not been implemented for \(paymentMethodType)")
        }
    }()
    init(paymentMethodType: STPPaymentMethodType, canEdit: Bool, canRemove: Bool) {
        guard supportedPaymentMethods.contains(paymentMethodType) else {
               fatalError("Unsupported payment type \(paymentMethodType) in PollingViewModel")
        }
        self.paymentMethodType = paymentMethodType
        self.canEdit = canEdit
        self.canRemove = canRemove
    }
}
