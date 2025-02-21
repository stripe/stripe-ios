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
    static func makeSEPADebit(viewModel: UpdatePaymentMethodViewModel) -> PaymentMethodElement {
        let nameElement: SectionElement = {
            return SectionElement(elements: [TextFieldElement.NameConfiguration(defaultValue: viewModel.paymentMethod.billingDetails?.name, isEditable: false).makeElement(theme: viewModel.appearance.asElementsTheme)], theme: viewModel.appearance.asElementsTheme)
        }()
        let emailElement: SectionElement = {
            return SectionElement(elements: [TextFieldElement.EmailConfiguration(defaultValue: viewModel.paymentMethod.billingDetails?.email, isEditable: false).makeElement(theme: viewModel.appearance.asElementsTheme)], theme: viewModel.appearance.asElementsTheme)
        }()
        let ibanElement: SectionElement = {
            return SectionElement(elements: [TextFieldElement.LastFourIBANConfiguration(lastFour: viewModel.paymentMethod.sepaDebit?.last4 ?? "0000").makeElement(theme: viewModel.appearance.asElementsTheme)], theme: viewModel.appearance.asElementsTheme)
        }()
        nameElement.disableAppearance()
        emailElement.disableAppearance()
        ibanElement.disableAppearance()

        return FormElement(elements: [nameElement, emailElement, ibanElement],
                                   theme: viewModel.appearance.asElementsTheme,
                                   customSpacing: [(nameElement, ElementsUI.formSpacing - 4.0),
                                                   (emailElement, ElementsUI.formSpacing - 4.0), ])
    }
}
