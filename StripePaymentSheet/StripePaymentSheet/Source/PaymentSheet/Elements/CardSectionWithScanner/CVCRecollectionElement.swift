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

final class CVCRecollectionElement: ContainerElement {

    weak var delegate: ElementDelegate?

    lazy var view: UIView = {
        return cvcSection.view
    }()

    var elements: [Element] {
        return [cvcSection]
    }

    let theme: ElementsUITheme

    let defaultValues: DefaultValues

    lazy var cardBrand: STPCardBrand = .unknown

    lazy var cvcElementConfiguration: TextFieldElement.CVCConfiguration = {
        return TextFieldElement.CVCConfiguration(defaultValue: defaultValues.cvc) {
            // TODO: Get brand from selected payment method
            return self.cardBrand
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
            // TODO: Translations
            title: "Security Code",
            elements: subElements,
            theme: theme
        )
        sectionElement.delegate = self
        return sectionElement
    }()

    func didUpdateCardBrand(updatedCardBrand: STPCardBrand) {
        // Update the CVC field if the card brand changes
        if self.cardBrand != updatedCardBrand {
            self.cardBrand = updatedCardBrand
            cvcElement.setText("")//cvcElement.text) // A hack to get the CVC to update
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
        theme: ElementsUITheme = .default
    ) {
        self.theme = theme
        self.defaultValues = defaultValues
        cvcSection.delegate = self
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
