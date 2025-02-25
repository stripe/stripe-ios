//
//  UpdatePaymentMethodViewController+Configuration.swift
//  StripePaymentSheet
//
//  Created by Joyce Qin on 11/15/24.
//

import Foundation
@_spi(STP) import StripeCore
import UIKit

extension UpdatePaymentMethodViewController {
    struct Configuration {
        let paymentMethod: STPPaymentMethod
        let appearance: PaymentSheet.Appearance
        let hostedSurface: HostedSurface
        let cardBrandFilter: CardBrandFilter
        let canRemove: Bool
        let isCBCEligible: Bool
        let canSetAsDefaultPM: Bool
        let isDefault: Bool

        var canEdit: Bool {
            return canUpdateCardBrand || canSetAsDefaultPM
        }

        var canUpdateCardBrand: Bool {
            guard paymentMethod.type == .card else {
                return false
            }
            let availableBrands = paymentMethod.card?.networks?.available.map { $0.toCardBrand }.compactMap { $0 }
            let filteredCardBrands = availableBrands?.filter { cardBrandFilter.isAccepted(cardBrand: $0) } ?? []
            return isCBCEligible && filteredCardBrands.count > 1
        }

        var header: String? {
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
        }

        var footnote: String? {
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
        }

        init(paymentMethod: STPPaymentMethod, appearance: PaymentSheet.Appearance, hostedSurface: HostedSurface, cardBrandFilter: CardBrandFilter = .default, canRemove: Bool, isCBCEligible: Bool, allowsSetAsDefaultPM: Bool = false, isDefault: Bool = false) {
            if !PaymentSheet.supportedSavedPaymentMethods.contains(paymentMethod.type) {
                assertionFailure("Unsupported payment type \(paymentMethod.type) in UpdatePaymentMethodViewModel")
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
}
