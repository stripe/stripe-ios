//
//  SavedPaymentMethodFormFactory+SEPADebit.swift
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
    func makeSEPADebit() -> UIView {
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
        let stackView = UIStackView(arrangedSubviews: [nameElement.view, emailElement.view, ibanElement.view])
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.axis = .vertical
        stackView.setCustomSpacing(8, after: nameElement.view) // custom spacing from figma
        stackView.setCustomSpacing(8, after: emailElement.view) // custom spacing from figma
        return stackView
    }
}
