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
        switch configuration.paymentMethod.linkPaymentDetails {
        case .card(let cardDetails):
            return makeLinkCard(cardDetails: cardDetails, configuration: configuration)
        case .bankAccount(let bankDetails):
            return makeLinkBankAccount(bankAccount: bankDetails, configuration: configuration)
        default:
            fatalError("Cannot make payment method form for Link payment method.")
        }
    }

    private func makeLinkCard(
        cardDetails: LinkPaymentDetails.Card,
        configuration: UpdatePaymentMethodViewController.Configuration
    ) -> PaymentMethodElement {
        let theme = configuration.appearance.asElementsTheme
        let panElement: TextFieldElement = {
            let panElementConfig = TextFieldElement.LastFourConfiguration(
                lastFour: cardDetails.last4,
                editConfiguration: .readOnly,
                cardBrand: cardDetails.brand,
                cardBrandDropDown: nil
            )

            let panElement = panElementConfig.makeElement(theme: theme)
            return panElement
        }()

        let expiryDateElement: Element = {
            let expiryDate = CardExpiryDate(month: cardDetails.expMonth, year: cardDetails.expYear)
            let expirationDateConfig = TextFieldElement.ExpiryDateConfiguration(defaultValue: expiryDate.displayString,
                                                                                editConfiguration: .readOnly)
            let expirationField = expirationDateConfig.makeElement(theme: theme)
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
            return TextFieldElement.CensoredCVCConfiguration(brand: cardDetails.brand).makeElement(theme: theme)
        }()

        let cardSection: SectionElement = {
            let allSubElements: [Element?] = [
                panElement,
                SectionElement.MultiElementRow([expiryDateElement, cvcElement], theme: theme),
            ]
            return SectionElement(title: nil, // billingAddressSection != nil ? String.Localized.card_information : nil,
                                  elements: allSubElements.compactMap { $0 },
                                  theme: theme)
        }()
        return FormElement(elements: [cardSection], theme: theme)
    }

    private func makeLinkBankAccount(
        bankAccount: LinkPaymentDetails.BankDetails,
        configuration: UpdatePaymentMethodViewController.Configuration
    ) -> PaymentMethodElement {
        let bankAccountElement: SectionElement = {
            let usBankTextFieldElement = TextFieldElement.USBankNumberConfiguration(
                bankName: bankAccount.bankName,
                lastFour: bankAccount.last4
            ).makeElement(theme: configuration.appearance.asElementsTheme)
            return SectionElement(elements: [usBankTextFieldElement], theme: configuration.appearance.asElementsTheme)
        }()

        return FormElement(
            elements: [bankAccountElement],
            theme: configuration.appearance.asElementsTheme
        )
    }
}
