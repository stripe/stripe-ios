//
//  SavedPaymentMethodFormFactory+SEPADebit.swift
//  StripePaymentSheet
//
//  Created by Joyce Qin on 11/22/24.
//

import Foundation
@_spi(STP) import StripeUICore
import UIKit

extension SavedPaymentMethodFormFactory {
    func makeSEPADebit(configuration: UpdatePaymentMethodViewController.Configuration) -> PaymentMethodElement {
        let nameElement: SectionElement = {
            return SectionElement(elements: [TextFieldElement.NameConfiguration(defaultValue: configuration.paymentMethod.billingDetails?.name, editConfiguration: .readOnly).makeElement(theme: configuration.appearance.asElementsTheme)], theme: configuration.appearance.asElementsTheme)
        }()
        let emailElement: SectionElement = {
            return SectionElement(elements: [TextFieldElement.EmailConfiguration(defaultValue: configuration.paymentMethod.billingDetails?.email, editConfiguration: .readOnly).makeElement(theme: configuration.appearance.asElementsTheme)], theme: configuration.appearance.asElementsTheme)
        }()
        let ibanElement: SectionElement = {
            return SectionElement(elements: [TextFieldElement.LastFourIBANConfiguration(lastFour: configuration.paymentMethod.sepaDebit?.last4 ?? "0000").makeElement(theme: configuration.appearance.asElementsTheme)], theme: configuration.appearance.asElementsTheme)
        }()
        return FormElement(elements: [nameElement, emailElement, ibanElement],
                                   theme: configuration.appearance.asElementsTheme,
                                   customSpacing: [(nameElement, ElementsUI.formSpacing - 4.0),
                                                   (emailElement, ElementsUI.formSpacing - 4.0), ])
    }
}
