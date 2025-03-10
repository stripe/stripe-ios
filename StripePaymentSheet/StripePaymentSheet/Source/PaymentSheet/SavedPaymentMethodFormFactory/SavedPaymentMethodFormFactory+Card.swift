//
//  SavedPaymentMethodFormFactory+Card.swift
//  StripePaymentSheet
//
//  Created by Joyce Qin on 11/22/24.
//

import Foundation
@_spi(STP) import StripeCore
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

        let billingAddressSection: PaymentMethodElementWrapper<AddressSectionElement>? = {
            guard configuration.canUpdate else {
                return nil
            }
            switch configuration.billingDetailsCollectionConfiguration.address {
            case .automatic:
                return makeBillingAddressSection(configuration, collectionMode: .countryAndPostal(), countries: nil)
            case .full:
                return makeBillingAddressSection(configuration, collectionMode: .all(), countries: nil)
            case .never:
                return nil
            }
        }()

        let cardSection: SectionElement = {
            let allSubElements: [Element?] = [
                panElement,
                SectionElement.HiddenElement(cardBrandDropDown),
                SectionElement.MultiElementRow([expiryDateElement, cvcElement]),
            ]
            return SectionElement(title: billingAddressSection != nil ? String.Localized.card_information : nil,
                                  elements: allSubElements.compactMap { $0 },
                                  theme: configuration.appearance.asElementsTheme)
        }()
        return FormElement(elements: [cardSection, billingAddressSection], theme: configuration.appearance.asElementsTheme)
    }

    func makeBillingAddressSection(
        _ configuration: UpdatePaymentMethodViewController.Configuration,
        collectionMode: AddressSectionElement.CollectionMode = .all(),
        countries: [String]? = nil) -> PaymentMethodElementWrapper<AddressSectionElement> {
            let section = AddressSectionElement(
                title: String.Localized.billing_address_lowercase,
                countries: countries,
                defaults: currentBillingDetails(paymentMethod: configuration.paymentMethod),
                collectionMode: collectionMode,
                additionalFields: .init(
                    billingSameAsShippingCheckbox: .disabled
                ),
                theme: configuration.appearance.asElementsTheme
            )
            return PaymentSheetFormFactory.makeBillingAddressPaymentMethodWrapper(section: section, countryAPIPath: nil)
    }

    func currentBillingDetails(paymentMethod: STPPaymentMethod) -> AddressSectionElement.AddressDetails {
        let address = AddressSectionElement.AddressDetails.Address(city: paymentMethod.billingDetails?.address?.city,
                                                                   country: paymentMethod.billingDetails?.address?.country,
                                                                   line1: paymentMethod.billingDetails?.address?.line1,
                                                                   line2: paymentMethod.billingDetails?.address?.line2,
                                                                   postalCode: paymentMethod.billingDetails?.address?.postalCode,
                                                                   state: paymentMethod.billingDetails?.address?.state)
        return AddressSectionElement.AddressDetails(name: nil, phone: nil, address: address)
    }
}
