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
    let canUpdate: Bool
    let canSetAsDefaultPM: Bool
    let isDefault: Bool
    var errorState: Bool = false
    private var lastCardBrandLogSelectedEventSent: String?

    var hasChangedDefaultPaymentMethodCheckbox: Bool = false
    var shouldShowSaveButton: Bool {
        return canUpdateCardBrand || canSetAsDefaultPM || canUpdate
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
            if canUpdate {
                return nil
            }
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

    init(paymentMethod: STPPaymentMethod, appearance: PaymentSheet.Appearance, hostedSurface: HostedSurface, cardBrandFilter: CardBrandFilter = .default, canRemove: Bool, canUpdate: Bool, isCBCEligible: Bool, allowsSetAsDefaultPM: Bool = false, isDefault: Bool = false) {
        if !PaymentSheet.supportedSavedPaymentMethods.contains(paymentMethod.type) {
            assertionFailure("Unsupported payment type \(paymentMethod.type) in UpdatePaymentMethodViewModel")
        }
        self.paymentMethod = paymentMethod
        self.appearance = appearance
        self.hostedSurface = hostedSurface
        self.cardBrandFilter = cardBrandFilter
        self.canRemove = canRemove
        self.canUpdate = canUpdate
        self.isCBCEligible = isCBCEligible
        self.canSetAsDefaultPM = allowsSetAsDefaultPM && !isDefault
        self.isDefault = isDefault
    }

    func updateParams(paymentMethodElement: PaymentMethodElement) -> UpdatePaymentMethodOptions?{
        let confirmParams = IntentConfirmParams(type: PaymentSheet.PaymentMethodType.stripe(.card))

        if let params = paymentMethodElement.updateParams(params: confirmParams),
           let cardParams = params.paymentMethodParams.card,
           let originalPaymentMethodCard = paymentMethod.card,
           hasChangedFields(original: originalPaymentMethodCard, updated: cardParams) {
            return .card(paymentMethodCardParams: cardParams)
        }
        return nil
    }
    func hasChangedFields(original: STPPaymentMethodCard, updated: STPPaymentMethodCardParams) -> Bool {
        let cardBrandChanged = canUpdateCardBrand && original.preferredDisplayBrand != updated.networks?.preferred?.toCardBrand
        let updatedMM = NSNumber(value: original.expMonth) != updated.expMonth
        let updatedYY = original.twoDigitYear != updated.expYear
        return cardBrandChanged || updatedMM || updatedYY
    }

    func logCardBrandSelected(selectedCardBrand: STPCardBrand) {
        // Send update metric if needed
        let preferredNetworkAPIValue = STPCardBrandUtilities.apiValue(from: selectedCardBrand)
        if preferredNetworkAPIValue != self.lastCardBrandLogSelectedEventSent {
            STPAnalyticsClient.sharedClient.logPaymentSheetEvent(event: hostedSurface.analyticEvent(for: .cardBrandSelected),
                                                                 params: ["selected_card_brand": preferredNetworkAPIValue,
                                                                          "cbc_event_source": "edit", ])
            self.lastCardBrandLogSelectedEventSent = preferredNetworkAPIValue
        }
    }
}

extension UpdatePaymentMethodViewModel {
    enum UpdatePaymentMethodOptions {
        case card(paymentMethodCardParams: STPPaymentMethodCardParams)
    }
}
extension STPPaymentMethodCard {
    var twoDigitYear: NSNumber? {
        if let year = Int(String(expYear).suffix(2)) {
            return NSNumber(value: year)
        }
        return nil
    }
}
