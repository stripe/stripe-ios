//
//  SavedPaymentMethodFormFactory.swift
//  StripePaymentSheet
//
//  Created by Joyce Qin on 11/20/24.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
@_spi(STP) import StripePaymentsUI
@_spi(STP) import StripeUICore
import UIKit

protocol SavedPaymentMethodFormFactoryDelegate: AnyObject {
    func didUpdate(_: Element, shouldEnableSaveButton: Bool)
}

class SavedPaymentMethodFormFactory {
    let viewModel: UpdatePaymentMethodViewModel
    weak var delegate: SavedPaymentMethodFormFactoryDelegate?

    init(viewModel: UpdatePaymentMethodViewModel) {
        self.viewModel = viewModel
    }

    func makePaymentMethodForm() -> UIView {
        switch viewModel.paymentMethod.type {
        case .card:
            return makeCard()
        case .USBankAccount:
            return usBankAccountSection
        case .SEPADebit:
            return sepaDebitSection
        default:
            fatalError("Cannot make payment method form for payment method type \(viewModel.paymentMethod.type).")
        }
    }

    private lazy var usBankAccountSection: UIStackView = {
        let nameElement: SectionElement = {
            return SectionElement(elements: [TextFieldElement.NameConfiguration(defaultValue: viewModel.paymentMethod.billingDetails?.name, isEditable: false).makeElement(theme: viewModel.appearance.asElementsTheme)])
        }()
        let emailElement: SectionElement = {
            return SectionElement(elements: [TextFieldElement.EmailConfiguration(defaultValue: viewModel.paymentMethod.billingDetails?.email, isEditable: false).makeElement(theme: viewModel.appearance.asElementsTheme)])
        }()
        let bankAccountElement: SectionElement = {
            return SectionElement(elements: [TextFieldElement.USBankNumberConfiguration(bankName: viewModel.paymentMethod.usBankAccount?.bankName ?? "Bank name", lastFour: viewModel.paymentMethod.usBankAccount?.last4 ?? "").makeElement(theme: viewModel.appearance.asElementsTheme)])
        }()
        let stackView = UIStackView(arrangedSubviews: [nameElement.view, emailElement.view, bankAccountElement.view])
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.axis = .vertical
        stackView.setCustomSpacing(8, after: nameElement.view) // custom spacing from figma
        stackView.setCustomSpacing(8, after: emailElement.view) // custom spacing from figma
        return stackView
    }()

    private lazy var sepaDebitSection: UIStackView = {
        let nameElement: SectionElement = {
            return SectionElement(elements: [TextFieldElement.NameConfiguration(defaultValue: viewModel.paymentMethod.billingDetails?.name, isEditable: false).makeElement(theme: viewModel.appearance.asElementsTheme)])
        }()
        let emailElement: SectionElement = {
            return SectionElement(elements: [TextFieldElement.EmailConfiguration(defaultValue: viewModel.paymentMethod.billingDetails?.email, isEditable: false).makeElement(theme: viewModel.appearance.asElementsTheme)])
        }()
        let ibanElement: SectionElement = {
            return SectionElement(elements: [TextFieldElement.LastFourIBANConfiguration(lastFour: viewModel.paymentMethod.sepaDebit?.last4 ?? "0000").makeElement(theme: viewModel.appearance.asElementsTheme)])
        }()
        let stackView = UIStackView(arrangedSubviews: [nameElement.view, emailElement.view, ibanElement.view])
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.axis = .vertical
        stackView.setCustomSpacing(8, after: nameElement.view) // custom spacing from figma
        stackView.setCustomSpacing(8, after: emailElement.view) // custom spacing from figma
        return stackView
    }()
}

// MARK: ElementDelegate
extension SavedPaymentMethodFormFactory: ElementDelegate {
    func continueToNextField(element: Element) {
        // no-op
    }

    func didUpdate(element: Element) {
        switch viewModel.paymentMethod.type {
        case .card:
            delegate?.didUpdate(_: element, shouldEnableSaveButton: viewModel.selectedCardBrand != viewModel.paymentMethod.card?.preferredDisplayBrand)
        default:
            break
        }
    }
}
