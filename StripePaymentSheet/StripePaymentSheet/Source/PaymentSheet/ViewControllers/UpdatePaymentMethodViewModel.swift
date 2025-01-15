//
//  UpdatePaymentMethodViewModel.swift
//  StripePaymentSheet
//
//  Created by Joyce Qin on 11/15/24.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
@_spi(STP) import StripePaymentsUI
@_spi(STP) import StripeUICore
import UIKit

class UpdatePaymentMethodViewModel {
    let paymentMethod: STPPaymentMethod
    let appearance: PaymentSheet.Appearance
    let hostedSurface: HostedSurface
    let cardBrandFilter: CardBrandFilter
    let canRemove: Bool
    let canUpdateCardBrand: Bool
    let allowsSetAsDefaultPM: Bool
    let isDefault: Bool

    var selectedCardBrand: STPCardBrand?
    var errorState: Bool = false
    var hasChangedCardBrand: Bool = false
    var hasChangedDefaultPaymentMethodCheckbox: Bool = false
    var canEdit: Bool {
        return canUpdateCardBrand || allowsSetAsDefaultPM
    }
    var hasUpdates: Bool {
        return hasChangedCardBrand || hasChangedDefaultPaymentMethodCheckbox
    }

    lazy var header: String = {
        switch paymentMethod.type {
        case .card:
            return .Localized.manage_card
        case .USBankAccount:
            return .Localized.manage_us_bank_account
        case .SEPADebit:
            return .Localized.manage_sepa_debit
        default:
            fatalError("Updating payment method has not been implemented for \(paymentMethod.type)")
        }
    }()

    lazy var footnote: String = {
        switch paymentMethod.type {
        case .card:
            return canUpdateCardBrand ? .Localized.only_card_brand_can_be_changed : .Localized.card_details_cannot_be_changed
        case .USBankAccount:
            return .Localized.bank_account_details_cannot_be_changed
        case .SEPADebit:
            return .Localized.sepa_debit_details_cannot_be_changed
        default:
            fatalError("Updating payment method has not been implemented for \(paymentMethod.type)")
        }
    }()

    init(paymentMethod: STPPaymentMethod, appearance: PaymentSheet.Appearance, hostedSurface: HostedSurface, cardBrandFilter: CardBrandFilter = .default, canRemove: Bool, canUpdateCardBrand: Bool, allowsSetAsDefaultPM: Bool = false, isDefault: Bool = false) {
        guard PaymentSheet.supportedSavedPaymentMethods.contains(paymentMethod.type) else {
            fatalError("Unsupported payment type \(paymentMethod.type) in UpdatePaymentMethodViewModel")
        }
        self.paymentMethod = paymentMethod
        self.appearance = appearance
        self.hostedSurface = hostedSurface
        self.cardBrandFilter = cardBrandFilter
        self.canRemove = canRemove
        self.canUpdateCardBrand = canUpdateCardBrand
        self.allowsSetAsDefaultPM = allowsSetAsDefaultPM
        self.isDefault = isDefault
    }
}
