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
    let isCBCEligible: Bool
    let canSetAsDefaultPM: Bool
    let isDefault: Bool

    var selectedCardBrand: STPCardBrand?
    var errorState: Bool = false
    var hasChangedCardBrand: Bool = false
    var hasChangedDefaultPaymentMethodCheckbox: Bool = false
    var canEdit: Bool {
        return canUpdateCardBrand || canSetAsDefaultPM
    }
    var hasUpdates: Bool {
        return hasChangedCardBrand || hasChangedDefaultPaymentMethodCheckbox
    }
    var canUpdateCardBrand: Bool {
        guard paymentMethod.type == .card else {
            return false
        }
        let availableBrands = paymentMethod.card?.networks?.available.map { $0.toCardBrand }.compactMap { $0 }
        let filteredCardBrands = availableBrands?.filter { cardBrandFilter.isAccepted(cardBrand: $0) } ?? []
        return isCBCEligible && filteredCardBrands.count > 1
    }

    lazy var header: String? = {
        switch paymentMethod.type {
        case .card:
            return .Localized.manage_card
        case .USBankAccount:
            return .Localized.manage_us_bank_account
        case .SEPADebit:
            return .Localized.manage_sepa_debit
        default:
            assertionFailure("Updating payment method has not been implemented for \(paymentMethod.type)")
            return nil
        }
    }()

    lazy var footnote: String? = {
        switch paymentMethod.type {
        case .card:
            return canUpdateCardBrand ? .Localized.only_card_brand_can_be_changed : .Localized.card_details_cannot_be_changed
        case .USBankAccount:
            return .Localized.bank_account_details_cannot_be_changed
        case .SEPADebit:
            return .Localized.sepa_debit_details_cannot_be_changed
        default:
            assertionFailure("Updating payment method has not been implemented for \(paymentMethod.type)")
            return nil
        }
    }()

    init(paymentMethod: STPPaymentMethod, appearance: PaymentSheet.Appearance, hostedSurface: HostedSurface, cardBrandFilter: CardBrandFilter = .default, canRemove: Bool, isCBCEligible: Bool, allowsSetAsDefaultPM: Bool = false, isDefault: Bool = false) {
        guard PaymentSheet.supportedSavedPaymentMethods.contains(paymentMethod.type) else {
            assertionFailure("Unsupported payment type \(paymentMethod.type) in UpdatePaymentMethodViewModel")
            self.paymentMethod = STPPaymentMethod(stripeId: "", type: .unknown)
            self.appearance = PaymentSheet.Appearance()
            self.hostedSurface = .paymentSheet
            self.cardBrandFilter = .default
            self.canRemove = false
            self.isCBCEligible = false
            self.canSetAsDefaultPM = false
            self.isDefault = false
            return
        }
        self.paymentMethod = paymentMethod
        self.appearance = appearance
        self.hostedSurface = hostedSurface
        self.cardBrandFilter = cardBrandFilter
        self.canRemove = canRemove
        self.isCBCEligible = isCBCEligible
        self.canSetAsDefaultPM = allowsSetAsDefaultPM && !isDefault
        self.isDefault = isDefault
    }
}
