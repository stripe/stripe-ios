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
            let panElementConfig = TextFieldElement.LastFourConfiguration(lastFour: configuration.paymentMethod.card?.last4 ?? "",
                                                                          editConfiguration: cardBrandDropDown != nil ? .readOnlyWithoutDisabledAppearance : .readOnly,
                                                                          cardBrand: configuration.paymentMethod.calculateCardBrandToDisplay(),
                                                                          cardBrandDropDown: cardBrandDropDown?.element)

            let panElement = panElementConfig.makeElement(theme: configuration.appearance.asElementsTheme)
            return panElement
        }()

        let expiryDateElement: Element = {
            let expiryDate = CardExpiryDate(month: configuration.paymentMethod.card?.expMonth ?? 0,
                                            year: configuration.paymentMethod.card?.expYear ?? 0)
            let expirationDateConfig = TextFieldElement.ExpiryDateConfiguration(defaultValue: expiryDate.displayString,
                                                                                editConfiguration: configuration.canUpdate ? .editable : .readOnly)
            let expirationField = expirationDateConfig.makeElement(theme: configuration.appearance.asElementsTheme)
            let wrappedElement = PaymentMethodElementWrapper<TextFieldElement>(expirationField) { field, params in
                if let month = Int(field.text.prefix(2)) {
                    cardParams(for: params).expMonth = NSNumber(value: month)
                }
                if let year = Int(field.text.suffix(2)) {
                    cardParams(for: params).expYear = NSNumber(value: year)
                }
                return params
            }
            return wrappedElement
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
            return SectionElement(elements: allSubElements.compactMap { $0 }, theme: configuration.appearance.asElementsTheme)
        }()
        return cardSection
    }
}
