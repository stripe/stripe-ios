//
//  SavedPaymentMethodFormFactory+USBankAccount.swift
//  StripePaymentSheet
//
//  Created by Joyce Qin on 11/22/24.
//

import Foundation
@_spi(STP) import StripeUICore
import UIKit

extension SavedPaymentMethodFormFactory {
    func makeUSBankAccount(configuration: UpdatePaymentMethodViewController.Configuration) -> PaymentMethodElement {
        let nameElement: SectionElement = {
            let nameTextFieldElement = TextFieldElement.NameConfiguration(defaultValue: configuration.paymentMethod.billingDetails?.name, editConfiguration: .readOnly).makeElement(theme: configuration.appearance.asElementsTheme)
            return SectionElement(elements: [nameTextFieldElement], theme: configuration.appearance.asElementsTheme)
        }()
        let emailElement: SectionElement = {
            let emailTextFieldElement = TextFieldElement.EmailConfiguration(defaultValue: configuration.paymentMethod.billingDetails?.email, editConfiguration: .readOnly).makeElement(theme: configuration.appearance.asElementsTheme)
            return SectionElement(elements: [emailTextFieldElement], theme: configuration.appearance.asElementsTheme)
        }()
        let bankAccountElement: SectionElement = {
            let usBankTextFieldElement = TextFieldElement.USBankNumberConfiguration(bankName: configuration.paymentMethod.usBankAccount?.bankName ?? "Bank name", lastFour: configuration.paymentMethod.usBankAccount?.last4 ?? "").makeElement(theme: configuration.appearance.asElementsTheme)
            return SectionElement(elements: [usBankTextFieldElement], theme: configuration.appearance.asElementsTheme)
        }()

        return FormElement(elements: [nameElement, emailElement, bankAccountElement],
                           theme: configuration.appearance.asElementsTheme,
                           customSpacing: [(nameElement, ElementsUI.formSpacing - 4.0),
                                           (emailElement, ElementsUI.formSpacing - 4.0), ])
    }
}
