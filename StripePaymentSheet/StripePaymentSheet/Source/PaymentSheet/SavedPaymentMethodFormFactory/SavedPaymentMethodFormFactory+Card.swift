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
    func makeCard() -> Element {
        let cardBrandDropDown: DropdownFieldElement? = {
            guard viewModel.paymentMethod.isCoBrandedCard else { return nil }
            let cardBrands = viewModel.paymentMethod.card?.networks?.available.map({ STPCard.brand(from: $0) }).filter { viewModel.cardBrandFilter.isAccepted(cardBrand: $0) } ?? []
            let cardBrandDropDown = DropdownFieldElement.makeCardBrandDropdown(cardBrands: Set<STPCardBrand>(cardBrands),
                                                                               theme: viewModel.appearance.asElementsTheme,
                                                                               includePlaceholder: false) { [weak self] in
                guard let self = self else { return }
                let selectedCardBrand = viewModel.selectedCardBrand ?? .unknown
                let params = ["selected_card_brand": STPCardBrandUtilities.apiValue(from: selectedCardBrand), "cbc_event_source": "edit"]
                STPAnalyticsClient.sharedClient.logPaymentSheetEvent(event: viewModel.hostedSurface.analyticEvent(for: .openCardBrandDropdown),
                                                                     params: params)
            } didTapClose: { [weak self] in
                guard let self = self else { return }
                let selectedCardBrand = viewModel.selectedCardBrand ?? .unknown
                STPAnalyticsClient.sharedClient.logPaymentSheetEvent(event: viewModel.hostedSurface.analyticEvent(for: .closeCardBrandDropDown),
                                                                     params: ["selected_card_brand": STPCardBrandUtilities.apiValue(from: selectedCardBrand)])
            }

            // pre-select current card brand
            if let currentCardBrand = viewModel.paymentMethod.card?.preferredDisplayBrand,
               let indexToSelect = cardBrandDropDown.items.firstIndex(where: { $0.rawData == STPCardBrandUtilities.apiValue(from: currentCardBrand) }) {
                cardBrandDropDown.select(index: indexToSelect, shouldAutoAdvance: false)
                viewModel.selectedCardBrand = currentCardBrand
            }
            cardBrandDropDown.didUpdate = updateSelectedCardBrand
            return cardBrandDropDown
        }()

        let panElement: TextFieldElement = {
            return TextFieldElement.LastFourConfiguration(lastFour: viewModel.paymentMethod.card?.last4 ?? "", cardBrand: viewModel.paymentMethod.card?.brand, cardBrandDropDown: cardBrandDropDown).makeElement(theme: viewModel.appearance.asElementsTheme)
        }()

        let expiryDateElement: TextFieldElement = {
            let expiryDate = CardExpiryDate(month: viewModel.paymentMethod.card?.expMonth ?? 0, year: viewModel.paymentMethod.card?.expYear ?? 0)
            return TextFieldElement.ExpiryDateConfiguration(defaultValue: expiryDate.displayString, isEditable: false).makeElement(theme: viewModel.appearance.asElementsTheme)
        }()

        let cvcElement: TextFieldElement = {
            return TextFieldElement.CensoredCVCConfiguration(brand: self.viewModel.paymentMethod.card?.preferredDisplayBrand ?? .unknown).makeElement(theme: viewModel.appearance.asElementsTheme)
        }()

        let cardSection: SectionElement = {
            let allSubElements: [Element?] = [
                panElement,
                SectionElement.HiddenElement(cardBrandDropDown),
                SectionElement.MultiElementRow([expiryDateElement, cvcElement])
            ]
            let section = SectionElement(elements: allSubElements.compactMap { $0 }, theme: viewModel.appearance.asElementsTheme)
            section.disableAppearance()
            section.delegate = self
            viewModel.errorState = !expiryDateElement.validationState.isValid
            return section
        }()
        return cardSection
    }

    private func updateSelectedCardBrand(index: Int) {
        let cardBrands = viewModel.paymentMethod.card?.networks?.available.map({ STPCard.brand(from: $0) }).filter { viewModel.cardBrandFilter.isAccepted(cardBrand: $0) } ?? []
        viewModel.selectedCardBrand = cardBrands[index]
    }
}
