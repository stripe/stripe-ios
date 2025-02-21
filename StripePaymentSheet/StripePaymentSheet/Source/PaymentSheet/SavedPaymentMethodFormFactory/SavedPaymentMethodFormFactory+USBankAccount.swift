//
//  SavedPaymentMethodFormFactory+USBankAccount.swift
//  StripePaymentSheet
//
//  Created by Joyce Qin on 11/22/24.
//

import Foundation
@_spi(STP) import StripePayments
@_spi(STP) import StripePaymentsUI
@_spi(STP) import StripeUICore
import UIKit

extension SavedPaymentMethodFormFactory {
    static func makeUSBankAccount(viewModel: UpdatePaymentMethodViewModel) -> PaymentMethodElement {
        let nameElement: SectionElement = {
            let nameTextFieldElement = TextFieldElement.NameConfiguration(defaultValue: viewModel.paymentMethod.billingDetails?.name, isEditable: false).makeElement(theme: viewModel.appearance.asElementsTheme)
            return SectionElement(elements: [nameTextFieldElement], theme: viewModel.appearance.asElementsTheme)
        }()
        let emailElement: SectionElement = {
            let emailTextFieldElement = TextFieldElement.EmailConfiguration(defaultValue: viewModel.paymentMethod.billingDetails?.email, isEditable: false).makeElement(theme: viewModel.appearance.asElementsTheme)
            return SectionElement(elements: [emailTextFieldElement], theme: viewModel.appearance.asElementsTheme)
        }()
        let bankAccountElement: SectionElement = {
            let usBankTextFieldElement = TextFieldElement.USBankNumberConfiguration(bankName: viewModel.paymentMethod.usBankAccount?.bankName ?? "Bank name", lastFour: viewModel.paymentMethod.usBankAccount?.last4 ?? "").makeElement(theme: viewModel.appearance.asElementsTheme)
            return SectionElement(elements: [usBankTextFieldElement], theme: viewModel.appearance.asElementsTheme)
        }()
        nameElement.disableAppearance()
        emailElement.disableAppearance()
        bankAccountElement.disableAppearance()

        return FormElement(elements: [nameElement, emailElement, bankAccountElement], theme: viewModel.appearance.asElementsTheme)
    }
}
