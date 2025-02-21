//
//  SavedPaymentMethodFormFactory+Card.swift
//  StripePaymentSheet
//
//  Created by Joyce Qin on 11/22/24.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
@_spi(STP) import StripePaymentsUI
@_spi(STP) import StripeUICore
import UIKit

extension SavedPaymentMethodFormFactory {
    static func makeCard(viewModel: UpdatePaymentMethodViewModel) -> PaymentMethodElement {
        let cardBrandDropDown: PaymentMethodElementWrapper<DropdownFieldElement>? = {
            guard viewModel.isCBCEligible else {
                return nil
            }
            let cardBrands = viewModel.paymentMethod.card?.networks?.available.map({ STPCard.brand(from: $0) }) ?? []
            let disallowedCardBrands = cardBrands.filter { !viewModel.cardBrandFilter.isAccepted(cardBrand: $0) }

            let cardBrandDropDown = DropdownFieldElement.makeCardBrandDropdown(cardBrands: Set<STPCardBrand>(cardBrands),
                                                                               disallowedCardBrands: Set<STPCardBrand>(disallowedCardBrands),
                                                                               theme: viewModel.appearance.asElementsTheme,
                                                                               includePlaceholder: false)
            // pre-select current card brand
            if let currentCardBrand = viewModel.paymentMethod.card?.preferredDisplayBrand,
               let indexToSelect = cardBrandDropDown.items.firstIndex(where: { $0.rawData == STPCardBrandUtilities.apiValue(from: currentCardBrand) }) {
                cardBrandDropDown.select(index: indexToSelect, shouldAutoAdvance: false)
            }

            // Handler when user selects different card brand
            let wrappedElement = PaymentMethodElementWrapper<DropdownFieldElement>(cardBrandDropDown){ field, params in
                let cardBrands = viewModel.paymentMethod.card?.networks?.available.map({
                    STPCard.brand(from: $0)
                }).filter { viewModel.cardBrandFilter.isAccepted(cardBrand: $0) } ?? []
                let cardBrand = cardBrands[field.selectedIndex]
                let preferredNetworkAPIValue = STPCardBrandUtilities.apiValue(from: cardBrand)
                params.paymentMethodParams.card?.networks = .init(preferred: preferredNetworkAPIValue)
                return params
            }
            return wrappedElement
        }()
        let panElement: TextFieldElement = {
            return TextFieldElement.LastFourConfiguration(lastFour: viewModel.paymentMethod.card?.last4 ?? "", cardBrand: viewModel.paymentMethod.calculateCardBrandToDisplay(), cardBrandDropDown: cardBrandDropDown?.element).makeElement(theme: viewModel.appearance.asElementsTheme)
        }()

        let expiryDateElement: TextFieldElement = {
            let expiryDate = CardExpiryDate(month: viewModel.paymentMethod.card?.expMonth ?? 0, year: viewModel.paymentMethod.card?.expYear ?? 0)
            return TextFieldElement.ExpiryDateConfiguration(defaultValue: expiryDate.displayString, isEditable: false).makeElement(theme: viewModel.appearance.asElementsTheme)
        }()

        let cvcElement: TextFieldElement = {
            return TextFieldElement.CensoredCVCConfiguration(brand: viewModel.paymentMethod.card?.preferredDisplayBrand ?? .unknown).makeElement(theme: viewModel.appearance.asElementsTheme)
        }()

        let cardSection: SectionElement = {
            let allSubElements: [Element?] = [
                panElement,
                SectionElement.HiddenElement(cardBrandDropDown),
                SectionElement.MultiElementRow([expiryDateElement, cvcElement]),
            ]
            let section = SectionElement(elements: allSubElements.compactMap { $0 }, theme: viewModel.appearance.asElementsTheme)
            section.disableAppearance()
            viewModel.errorState = !expiryDateElement.validationState.isValid
            return section
        }()
        return cardSection
    }
}
