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

    let cvcSection: SectionElement
    let cvcElement: TextFieldElement
    let theme: ElementsUITheme

    struct DefaultValues {
        internal init(cvc: String? = nil) {
            self.cvc = cvc
        }
        let cvc: String?
    }
    static var counter = 0
    init(
        defaultValues: DefaultValues = .init(),
        theme: ElementsUITheme = .default
    ) {
        self.theme = theme


        let cvcElementConfiguration = TextFieldElement.CVCConfiguration(defaultValue: defaultValues.cvc) {
            // TODO: Get brand from selected payment method
            return .visa

        }
        let cvcElement = PaymentMethodElementWrapper(cvcElementConfiguration, theme: theme) { field, params in
            let cardOptions = STPConfirmCardOptions()
            cardOptions.cvc = field.text
            params.confirmPaymentMethodOptions.cardOptions = cardOptions
            return params
        }

        let allSubElements: [Element?] = [
            cvcElement
        ]
        let subElements = allSubElements.compactMap { $0 }
        self.cvcSection = SectionElement(
            // TODO: Translations
            title: "Security Code",
            elements: subElements,
            theme: theme
        )
        self.cvcElement = cvcElement.element
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
