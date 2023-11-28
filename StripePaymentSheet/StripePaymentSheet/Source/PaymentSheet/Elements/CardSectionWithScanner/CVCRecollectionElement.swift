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
        return stackView
    }()
    lazy var cvcElementConfiguration: TextFieldElement.CVCConfiguration = {
        return TextFieldElement.CVCConfiguration(defaultValue: defaultValues.cvc) { [weak self] in
            return self?.paymentMethod.card?.brand ?? .unknown
        }
    }()
    lazy var paymentMethodInfoView: PaymentMethodInformationView = {
        let paymentMethodInfoView = PaymentMethodInformationView(paymentMethod: paymentMethod,
                                                                 appearance: appearance)
        return paymentMethodInfoView
    }()
    lazy var stackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [
            paymentMethodInfoView,
            textFieldElement.view,
        ])
        stackView.distribution = .fillEqually
        stackView.spacing = 0
        stackView.axis = .horizontal
        stackView.layer.borderWidth = appearance.borderWidth
        stackView.layer.cornerRadius = appearance.cornerRadius
        stackView.layer.borderColor = appearance.colors.componentBorder.cgColor
        return stackView
    }()
    lazy var textFieldElement: TextFieldElement = {
        let textFieldElement = TextFieldElement(configuration: cvcElementConfiguration)
        textFieldElement.delegate = self
        textFieldElement.view.backgroundColor = appearance.colors.componentBackground
        textFieldElement.view.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMaxXMaxYCorner]
        textFieldElement.view.layer.cornerRadius = appearance.cornerRadius
        return textFieldElement
    }()

    let defaultValues: DefaultValues
    var paymentMethod: STPPaymentMethod
    let appearance: PaymentSheet.Appearance

    struct DefaultValues {
        internal init(cvc: String? = nil) {
            self.cvc = cvc
        }
        let cvc: String?
    }

    init(
        defaultValues: DefaultValues = .init(),
        paymentMethod: STPPaymentMethod,
        appearance: PaymentSheet.Appearance
    ) {
        self.defaultValues = defaultValues
        self.paymentMethod = paymentMethod
        self.appearance = appearance
    }

    func didFinishPresenting() {
        DispatchQueue.main.async {
            self.textFieldElement.beginEditing()
        }
    }
}

extension CVCRecollectionElement: ElementDelegate {
    func didUpdate(element: Element) {
        delegate?.didUpdate(element: textFieldElement)
    }
    func continueToNextField(element: Element) {
        delegate?.continueToNextField(element: textFieldElement)
    }
}

extension CVCRecollectionElement: PaymentMethodElement {
    func updateParams(params: IntentConfirmParams) -> IntentConfirmParams? {
        if case .valid = textFieldElement.validationState {
            let cardOptions = STPConfirmCardOptions()
            cardOptions.cvc = textFieldElement.text
            params.confirmPaymentMethodOptions.cardOptions = cardOptions
            return params
        }
        return nil
    }
}
