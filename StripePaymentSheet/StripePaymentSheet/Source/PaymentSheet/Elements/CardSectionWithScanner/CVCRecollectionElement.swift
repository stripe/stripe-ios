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
        return reconfirmationView
    }()

    lazy var reconfirmationView: CVCReconfirmationView = {
        return CVCReconfirmationView(defaultValues: defaultValues,
                                     paymentMethod: paymentMethod,
                                     appearance: appearance,
                                     elementDelegate: self)
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
            self.reconfirmationView.textFieldElement.beginEditing()
        }
    }
}

extension CVCRecollectionElement: ElementDelegate {
    func didUpdate(element: Element) {
        delegate?.didUpdate(element: reconfirmationView.textFieldElement)
    }
    func continueToNextField(element: Element) {
        delegate?.continueToNextField(element: reconfirmationView.textFieldElement)
    }
}

extension CVCRecollectionElement: PaymentMethodElement {
    func updateParams(params: IntentConfirmParams) -> IntentConfirmParams? {
        if case .valid = reconfirmationView.textFieldElement.validationState {
            let cardOptions = STPConfirmCardOptions()
            cardOptions.cvc = reconfirmationView.textFieldElement.text
            params.confirmPaymentMethodOptions.cardOptions = cardOptions
            return params
        }
        return nil
    }
}
