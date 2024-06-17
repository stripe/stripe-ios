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
    let collectsUserInput: Bool = true

    enum Mode {
        case inputOnly
        case detailedWithInput
    }
    weak var delegate: ElementDelegate?
    var mode: Mode
    lazy var view: UIView = {
        return cvcRecollectionView
    }()

    var isViewInitialized: Bool = false
    lazy var cvcRecollectionView: CVCRecollectionView = {
        isViewInitialized = true
        return CVCRecollectionView(defaultValues: defaultValues,
                                   paymentMethod: paymentMethod,
                                   mode: mode,
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
        mode: Mode,
        appearance: PaymentSheet.Appearance
    ) {
        self.defaultValues = defaultValues
        self.paymentMethod = paymentMethod
        self.appearance = appearance
        self.mode = mode
    }

    func beginEditing() {
        DispatchQueue.main.async {
            self.cvcRecollectionView.textFieldElement.beginEditing()
        }
    }

    var validationState: ElementValidationState {
        return cvcRecollectionView.textFieldElement.validationState
    }
    func clearTextFields() {
        self.cvcRecollectionView.textFieldElement.setText("")
    }
}

extension CVCRecollectionElement: ElementDelegate {
    func didUpdate(element: Element) {
        if isViewInitialized {
            cvcRecollectionView.update()
        }

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
