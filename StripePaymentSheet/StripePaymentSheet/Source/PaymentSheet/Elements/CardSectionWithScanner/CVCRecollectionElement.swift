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
        return cvcRecollectionView
    }()

    lazy var cvcRecollectionView: CVCRecollectionView = {
        return CVCRecollectionView(defaultValues: defaultValues,
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
            self.cvcRecollectionView.textFieldElement.beginEditing()
        }
    }
}

extension CVCRecollectionElement: ElementDelegate {
    func didUpdate(element: Element) {
        delegate?.didUpdate(element: cvcRecollectionView.textFieldElement)
    }
    func continueToNextField(element: Element) {
        delegate?.continueToNextField(element: cvcRecollectionView.textFieldElement)
    }
}

extension CVCRecollectionElement: PaymentMethodElement {
    func updateParams(params: IntentConfirmParams) -> IntentConfirmParams? {
        if case .valid = cvcRecollectionView.textFieldElement.validationState {
            let cardOptions = STPConfirmCardOptions()
            cardOptions.cvc = cvcRecollectionView.textFieldElement.text
            params.confirmPaymentMethodOptions.cardOptions = cardOptions
            return params
        }
        return nil
    }
}
