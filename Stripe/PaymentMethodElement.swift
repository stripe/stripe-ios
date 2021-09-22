//
//  PaymentMethodElement.swift
//  StripeiOS
//
//  Created by Yuki Tokuhiro on 9/14/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import UIKit
@_spi(STP) import StripeUICore

// MARK: - PaymentMethodElement protocol

protocol PaymentMethodElement: Element {
    /**
     Modify the params according to your input, or return nil if invalid.
     */
    func updateParams(params: IntentConfirmParams) -> IntentConfirmParams?
}

protocol PaymentMethodElementContainer: PaymentMethodElement {
    var elements: [Element] { get }
}

extension PaymentMethodElementContainer {
    func updateParams(params: IntentConfirmParams) -> IntentConfirmParams? {
        return elements
            .compactMap { $0 as? PaymentMethodElement }
            .reduce(params) { (params: IntentConfirmParams?, element: PaymentMethodElement) in
                guard let params = params else {
                    return nil
                }
                return element.updateParams(params: params)
            }
    }
}

// Some elements don't need to be wrapped to conform to PaymentMethodElement

extension FormElement: PaymentMethodElementContainer {}

extension SectionElement: PaymentMethodElementContainer {}

extension StaticElement: PaymentMethodElement {
    func updateParams(params: IntentConfirmParams) -> IntentConfirmParams? {
        return params
    }
}

// MARK: - PaymentMethodElementWrapper

/**
 A class that wraps an Element and adds a `paramsUpdater` closure, provided at initialization, used to implement `PaymentMethodElement.updateParams`
 */
class PaymentMethodElementWrapper<WrappedElementType: Element>: PaymentMethodElement {
    typealias ParamsUpdater = (WrappedElementType, IntentConfirmParams) -> IntentConfirmParams?
    
    let element: WrappedElementType

    // MARK: IntentConfirmParams updating glue
    let paramsUpdater: ParamsUpdater
    
    /**
     This only exists as a workaround to make initializers with a specific Element type e.g. TextFieldElement.
     */
    fileprivate init(privateElement element: WrappedElementType, paramsUpdater: @escaping ParamsUpdater) {
        self.element = element
        self.paramsUpdater = paramsUpdater
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

    func updateParams(params: IntentConfirmParams) -> IntentConfirmParams? {
        guard !element.view.isHidden else {
            return params
        }
        return paramsUpdater(element, params)
    }
}

extension PaymentMethodElementWrapper: Element {
    var delegate: ElementDelegate? {
        set {
            element.delegate = newValue
        }
        get {
            element.delegate
        }
    }
    
    var view: UIView {
        return element.view
    }
    
    func becomeResponder() -> Bool {
        return element.becomeResponder()
    }
    
    var errorText: String? {
        return element.errorText
    }
}
