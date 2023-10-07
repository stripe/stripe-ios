//
//  CVCRecollectionElement.swift
//  StripePaymentSheet
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
@_spi(STP) import StripePaymentsUI
@_spi(STP) import StripeUICore
import UIKit

final class CVCRecollectionElement: Element {

    weak var delegate: ElementDelegate?

    lazy var view: UIView = {
        return formElement.view
    }()

    var elements: [Element] {
        return [cvcSection]
    }

    let theme: ElementsUITheme

    let defaultValues: DefaultValues

    var cardBrand: STPCardBrand = .unknown

    lazy var cvcElementConfiguration: TextFieldElement.CVCConfiguration = {
        return TextFieldElement.CVCConfiguration(defaultValue: defaultValues.cvc) { [weak self] in
            return self?.cardBrand ?? .unknown
        }
    }()

    lazy var cvcElementPaymentMethodElement: PaymentMethodElementWrapper = {

        return PaymentMethodElementWrapper(cvcElementConfiguration, theme: theme) { field, params in
            let cardOptions = STPConfirmCardOptions()
            cardOptions.cvc = field.text
            params.confirmPaymentMethodOptions.cardOptions = cardOptions
            return params
        }
    }()

    lazy var cvcElement: TextFieldElement = {
        return cvcElementPaymentMethodElement.element
    }()

    lazy var cvcSection: SectionElement = {
        let allSubElements: [Element?] = [
            cvcElementPaymentMethodElement
        ]
        let subElements = allSubElements.compactMap { $0 }
        let sectionElement = SectionElement(
            title: STPLocalizedString("Security Code",
                                      "Title for input field which accepts the CVC/CVV for a card"),
            elements: subElements,
            theme: theme
        )
        return sectionElement
    }()

    lazy var formElement: FormElement = {
        let form = FormElement(autoSectioningElements: [cvcSection], theme: theme)
        form.delegate = self
        return form
    }()

    func didUpdateCardBrand(updatedCardBrand: STPCardBrand) {
        if self.cardBrand != updatedCardBrand {
            self.cardBrand = updatedCardBrand
            cvcElement.setText("") // A hack to get the CVC to update
        }
    }

    struct DefaultValues {
        internal init(cvc: String? = nil) {
            self.cvc = cvc
        }
        let cvc: String?
    }

    init(
        defaultValues: DefaultValues = .init(),
        cardBrand: STPCardBrand,
        theme: ElementsUITheme = .default
    ) {
        self.theme = theme
        self.cardBrand = cardBrand
        self.defaultValues = defaultValues
        cvcSection.delegate = self
    }

    func cleanupOnDismissal() {
        if case .invalid = cvcElement.validationState {
            cvcElement.setText("")
        }
    }
}

extension CVCRecollectionElement: ElementDelegate {
    func didUpdate(element: Element) {
        delegate?.didUpdate(element: self)
    }
    func continueToNextField(element: Element) {
        delegate?.continueToNextField(element: element)
    }
}

extension CVCRecollectionElement: PaymentMethodElement {
    func updateParams(params: IntentConfirmParams) -> IntentConfirmParams? {
        if let updatedParams = self.formElement.updateParams(params: params) {
            return updatedParams
        }
        return nil
    }
}
