//
//  SavedPaymentMethodFormFactory+Link.swift
//  StripePaymentSheet
//
//  Created by Till Hellmund on 4/26/25.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
@_spi(STP) import StripePaymentsUI
@_spi(STP) import StripeUICore
import UIKit

extension SavedPaymentMethodFormFactory {

    /// Creates a read-only form for viewing a Link payment method. No changes other than deleting the payment method are possible.
    func makeLink(configuration: UpdatePaymentMethodViewController.Configuration) -> PaymentMethodElement {
        let cardDetails = configuration.paymentMethod.linkPaymentDetails

        let panElement: TextFieldElement = {
            let panElementConfig = TextFieldElement.LastFourConfiguration(
                lastFour: cardDetails?.last4 ?? "",
                editConfiguration: .readOnly,
                cardBrand: cardDetails?.brand ?? .unknown,
                cardBrandDropDown: nil
            )

            let panElement = panElementConfig.makeElement(theme: configuration.appearance.asElementsTheme)
            return panElement
        }()

        let expiryDateElement: Element = {
            let expiryDate = CardExpiryDate(month: cardDetails?.expMonth ?? 0,
                                            year: cardDetails?.expYear ?? 0)
            let expirationDateConfig = TextFieldElement.ExpiryDateConfiguration(defaultValue: expiryDate.displayString,
                                                                                editConfiguration: .readOnly)
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
            return TextFieldElement.CensoredCVCConfiguration(brand: cardDetails?.brand ?? .unknown).makeElement(theme: configuration.appearance.asElementsTheme)
        }()

        let cardSection: SectionElement = {
            let allSubElements: [Element?] = [
                panElement,
                SectionElement.MultiElementRow([expiryDateElement, cvcElement]),
            ]
            return SectionElement(title: nil, // billingAddressSection != nil ? String.Localized.card_information : nil,
                                  elements: allSubElements.compactMap { $0 },
                                  theme: configuration.appearance.asElementsTheme)
        }()
        return FormElement(elements: [cardSection], theme: configuration.appearance.asElementsTheme)
    }
}
