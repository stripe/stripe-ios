//
//  PaymentMethodElementWrapper.swift
//  StripeiOS
//
//  Created by Yuki Tokuhiro on 3/26/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import UIKit
@_spi(STP) import StripeUICore

/**
 A class that wraps an Element and adds a `paramsUpdater` closure, provided at initialization, used to implement `PaymentMethodElement.updateParams`
 */
class PaymentMethodElementWrapper<WrappedElementType: Element> {
    typealias ParamsUpdater = (WrappedElementType, IntentConfirmParams) -> IntentConfirmParams?
    
    let element: WrappedElementType
    weak var delegate: ElementDelegate?

    // MARK: IntentConfirmParams updating glue
    let paramsUpdater: ParamsUpdater
    
    /**
     This only exists as a workaround to make initializers with a specific Element type e.g. TextFieldElement.
     */
    fileprivate init(privateElement element: WrappedElementType, paramsUpdater: @escaping ParamsUpdater) {
        self.element = element
        self.paramsUpdater = paramsUpdater
        defer {
            element.delegate = self
        }
    }
    
    convenience init(_ element: WrappedElementType, paramsUpdater: @escaping ParamsUpdater) {
        self.init(privateElement: element, paramsUpdater: paramsUpdater)
    }
    
    convenience init(_ element: TextFieldElement, paramsUpdater: @escaping ParamsUpdater) where WrappedElementType == TextFieldElement {
        self.init(privateElement: element) { textField, params in
            guard case .valid = textField.validationState else {
                return nil
            }
            return paramsUpdater(textField, params)
        }
    }
    convenience init(_ textFieldElementConfiguration: TextFieldElementConfiguration, theme: ElementsUITheme, paramsUpdater: @escaping ParamsUpdater) where WrappedElementType == TextFieldElement {
        let textFieldElement = TextFieldElement(configuration: textFieldElementConfiguration, theme: theme)
        self.init(textFieldElement, paramsUpdater: paramsUpdater)
    }
    
}

// MARK: - PaymentMethodElement
extension PaymentMethodElementWrapper: PaymentMethodElement {
    func updateParams(params: IntentConfirmParams) -> IntentConfirmParams? {
        guard !element.view.isHidden else {
            return params
        }
        return paramsUpdater(element, params)
    }
}

// MARK: - Element
extension PaymentMethodElementWrapper: Element {
    var view: UIView {
        return element.view
    }
    
    func beginEditing() -> Bool {
        return element.beginEditing()
    }
    
    var validationState: ElementValidationState {
        return element.validationState
    }
    
    var subLabelText: String? {
        return element.subLabelText
    }
}

// MARK: - ElementDelegate
extension PaymentMethodElementWrapper: ElementDelegate {
    public func didUpdate(element: Element) {
        delegate?.didUpdate(element: self)
    }
    
    public func continueToNextField(element: Element) {
        delegate?.continueToNextField(element: self)
    }
}
