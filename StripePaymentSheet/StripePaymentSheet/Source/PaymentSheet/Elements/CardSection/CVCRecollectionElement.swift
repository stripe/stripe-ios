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
    var elements: [Element] {
        return [textFieldElement]
    }

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
        return CVCRecollectionView(
            defaultValues: defaultValues,
            paymentMethod: paymentMethod,
            mode: mode,
            appearance: appearance,
            textFieldView: textFieldElement.view
        )
    }()

    let defaultValues: DefaultValues
    var paymentMethod: STPPaymentMethod
    let appearance: PaymentSheet.Appearance

    lazy var textFieldElement: TextFieldElement = {
        let textFieldElement = TextFieldElement(configuration: cvcElementConfiguration, theme: appearance.asElementsTheme)
        textFieldElement.view.layer.maskedCorners = mode == .detailedWithInput
        ? [.layerMaxXMinYCorner, .layerMaxXMaxYCorner]
        : [.layerMaxXMinYCorner, .layerMaxXMaxYCorner, .layerMinXMinYCorner, .layerMinXMaxYCorner]
        textFieldElement.delegate = self
        return textFieldElement
    }()

    lazy var cvcElementConfiguration: TextFieldElement.CVCConfiguration = {
        return TextFieldElement.CVCConfiguration(defaultValue: defaultValues.cvc) { [weak self] in
            return self?.paymentMethod.card?.brand ?? .unknown
        }
    }()

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
            self.textFieldElement.beginEditing()
        }
    }

    var validationState: ElementValidationState {
        return textFieldElement.validationState
    }
    func clearTextFields() {
        textFieldElement.setText("")
    }

    func updateErrorLabel() {
        if case let .invalid(error, shouldDisplay) = textFieldElement.validationState, shouldDisplay {
            cvcRecollectionView.errorLabel.text = error.localizedDescription
            cvcRecollectionView.errorLabel.isHidden = false
            cvcRecollectionView.errorLabel.textColor = appearance.asElementsTheme.colors.danger
        } else {
            cvcRecollectionView.errorLabel.text = nil
            cvcRecollectionView.errorLabel.isHidden = true
        }
    }
}

extension CVCRecollectionElement: ElementDelegate {
    func didUpdate(element: Element) {
        if isViewInitialized {
            updateErrorLabel()
        }

        delegate?.didUpdate(element: self)
    }
    func continueToNextField(element: Element) {
        delegate?.continueToNextField(element: self)
    }
}

extension CVCRecollectionElement: PaymentMethodElement {
    func updateParams(params: IntentConfirmParams) -> IntentConfirmParams? {
        if case .valid = textFieldElement.validationState {
            let cardOptions = STPConfirmCardOptions()
            let cvc = textFieldElement.text
            cardOptions.cvc = cvc
            #if DEBUG
            // There's no way to test an invalid recollected cvc in the API, so we hardcode a way:
            if cvc == "666" {
                cardOptions.cvc = "test_invalid_cvc"
            }
            #endif
            params.confirmPaymentMethodOptions.cardOptions = cardOptions
            return params
        }
        return nil
    }
}
