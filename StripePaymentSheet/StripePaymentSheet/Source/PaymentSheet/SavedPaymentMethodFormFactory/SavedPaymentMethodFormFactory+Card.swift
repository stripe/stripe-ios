//
//  SavedPaymentMethodFormFactory+Card.swift
//  StripePaymentSheet
//
//  Created by Joyce Qin on 11/22/24.
//

import Foundation
@_spi(STP) import StripePaymentsUI
@_spi(STP) import StripeUICore
import UIKit

extension SavedPaymentMethodFormFactory {
    func makeCard(configuration: UpdatePaymentMethodViewController.Configuration) -> PaymentMethodElement {
        let cardBrandDropDown: PaymentMethodElementWrapper<DropdownFieldElement>? = {
            guard configuration.isCBCEligible else {
                return nil
            }
            let cardBrands = configuration.paymentMethod.card?.networks?.available.map({ STPCard.brand(from: $0) }) ?? []
            let disallowedCardBrands = cardBrands.filter { !configuration.cardBrandFilter.isAccepted(cardBrand: $0) }

            let cardBrandDropDown = DropdownFieldElement.makeCardBrandDropdown(cardBrands: Set<STPCardBrand>(cardBrands),
                                                                               disallowedCardBrands: Set<STPCardBrand>(disallowedCardBrands),
                                                                               theme: configuration.appearance.asElementsTheme,
                                                                               includePlaceholder: false)
            // pre-select current card brand
            if let currentCardBrand = configuration.paymentMethod.card?.preferredDisplayBrand,
               let indexToSelect = cardBrandDropDown.items.firstIndex(where: { $0.rawData == STPCardBrandUtilities.apiValue(from: currentCardBrand) }) {
                cardBrandDropDown.select(index: indexToSelect, shouldAutoAdvance: false)
            }

            // Handler when user selects different card brand
            let wrappedElement = PaymentMethodElementWrapper<DropdownFieldElement>(cardBrandDropDown){ field, params in
                let cardBrands = configuration.paymentMethod.card?.networks?.available.map({
                    STPCard.brand(from: $0)
                }).filter { configuration.cardBrandFilter.isAccepted(cardBrand: $0) } ?? []
                let cardBrand = cardBrands[field.selectedIndex]
                let preferredNetworkAPIValue = STPCardBrandUtilities.apiValue(from: cardBrand)
                params.paymentMethodParams.card?.networks = .init(preferred: preferredNetworkAPIValue)
                return params
            }
            return wrappedElement
        }()
        let panElement: TextFieldElement = {
            return TextFieldElement.LastFourConfiguration(lastFour: configuration.paymentMethod.card?.last4 ?? "", cardBrand: configuration.paymentMethod.calculateCardBrandToDisplay(), cardBrandDropDown: cardBrandDropDown?.element).makeElement(theme: configuration.appearance.asElementsTheme)
        }()

        let expiryDateElement: TextFieldElement = {
            let expiryDate = CardExpiryDate(month: configuration.paymentMethod.card?.expMonth ?? 0,
                                            year: configuration.paymentMethod.card?.expYear ?? 0)
            return TextFieldElement.ExpiryDateConfiguration(defaultValue: expiryDate.displayString, isEditable: false)
                .makeElement(theme: configuration.appearance.asElementsTheme)
        }()

        let cvcElement: TextFieldElement = {
            return TextFieldElement.CensoredCVCConfiguration(brand: configuration.paymentMethod.card?.preferredDisplayBrand ?? .unknown).makeElement(theme: configuration.appearance.asElementsTheme)
        }()

        let cardSection: SectionElement = {
            let allSubElements: [Element?] = [
                panElement,
                SectionElement.HiddenElement(cardBrandDropDown),
                SectionElement.MultiElementRow([expiryDateElement, cvcElement]),
            ]
            let section = SectionElement(elements: allSubElements.compactMap { $0 }, theme: configuration.appearance.asElementsTheme)
            section.disableAppearance()

            return section
        }()
        return cardSection
    }
}
