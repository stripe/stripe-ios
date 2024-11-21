//
//  PaymentMethodForm.swift
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

protocol PaymentMethodFormDelegate: AnyObject {
    func didUpdate(_: Element, shouldEnableSaveButton: Bool)
}

class PaymentMethodForm {
    let viewModel: UpdatePaymentMethodViewModel
    weak var delegate: PaymentMethodFormDelegate?

    init(viewModel: UpdatePaymentMethodViewModel) {
        self.viewModel = viewModel
    }

    func makePaymentMethodForm() -> UIView {
        switch viewModel.paymentMethod.type {
        case .card:
            return cardSection.view
        case .USBankAccount:
            return usBankAccountSection
        case .SEPADebit:
            return sepaDebitSection
        default:
            fatalError("Updating payment method has not been implemented for \(viewModel.paymentMethod.type)")
        }
    }

    private lazy var cardBrandDropDown: DropdownFieldElement? = {
        guard viewModel.paymentMethod.isCoBrandedCard else { return nil }
        let cardBrands = viewModel.paymentMethod.card?.networks?.available.map({ STPCard.brand(from: $0) }).filter { viewModel.cardBrandFilter.isAccepted(cardBrand: $0) } ?? []
                    let cardBrandDropDown = DropdownFieldElement.makeCardBrandDropdown(cardBrands: Set<STPCardBrand>(cardBrands),
                                                                                       theme: viewModel.appearance.asElementsTheme,
                                                                                       includePlaceholder: false) { [self] in
                        let selectedCardBrand = viewModel.selectedCardBrand ?? .unknown
                        let params = ["selected_card_brand": STPCardBrandUtilities.apiValue(from: selectedCardBrand), "cbc_event_source": "edit"]
                        STPAnalyticsClient.sharedClient.logPaymentSheetEvent(event: viewModel.hostedSurface.analyticEvent(for: .openCardBrandDropdown),
                                                                             params: params)
                    } didTapClose: { [self] in
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
                    return cardBrandDropDown
    }()

    private lazy var panElement: TextFieldElement = {
        return TextFieldElement.LastFourConfiguration(lastFour: viewModel.paymentMethod.card?.last4 ?? "", cardBrandDropDown: cardBrandDropDown).makeElement(theme: viewModel.appearance.asElementsTheme)
    }()

    private lazy var expiryDateElement: TextFieldElement = {
        let expiryDate = CardExpiryDate(month: viewModel.paymentMethod.card?.expMonth ?? 0, year: viewModel.paymentMethod.card?.expYear ?? 0)
        let expiryDateElement = TextFieldElement.ExpiryDateConfiguration(defaultValue: expiryDate.displayString, isEditable: false).makeElement(theme: viewModel.appearance.asElementsTheme)
        return expiryDateElement
    }()

    private lazy var cvcElement: TextFieldElement = {
        let cvcConfiguration = TextFieldElement.CensoredCVCConfiguration(brand: self.viewModel.paymentMethod.card?.preferredDisplayBrand ?? .unknown)
        let cvcElement = cvcConfiguration.makeElement(theme: viewModel.appearance.asElementsTheme)
        return cvcElement
    }()

    private lazy var cardSection: SectionElement = {
        let allSubElements: [Element?] = [
            panElement,
            SectionElement.HiddenElement(cardBrandDropDown),
            SectionElement.MultiElementRow([expiryDateElement, cvcElement])
        ]
        let section = SectionElement(elements: allSubElements.compactMap { $0 }, theme: viewModel.appearance.asElementsTheme)
        section.delegate = self
        viewModel.errorState = !expiryDateElement.validationState.isValid
        return section
    }()

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
extension PaymentMethodForm: ElementDelegate {
    func continueToNextField(element: Element) {
        // no-op
    }

    func didUpdate(element: Element) {
        switch viewModel.paymentMethod.type {
        case .card:
            let selectedBrand = cardBrandDropDown?.selectedItem.rawData.toCardBrand
            let currentCardBrand = viewModel.paymentMethod.card?.preferredDisplayBrand ?? .unknown
            let shouldBeEnabled = selectedBrand != currentCardBrand && selectedBrand != .unknown
            viewModel.selectedCardBrand = selectedBrand
            delegate?.didUpdate(_: element, shouldEnableSaveButton: shouldBeEnabled)
        default:
            break
        }
    }
}
