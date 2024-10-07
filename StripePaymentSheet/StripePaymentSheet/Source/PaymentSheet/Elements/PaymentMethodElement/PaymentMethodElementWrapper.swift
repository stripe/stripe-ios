//
//  PaymentMethodElementWrapper.swift
//  StripePaymentSheet
//
//  Created by Yuki Tokuhiro on 3/26/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

@_spi(STP) import StripeUICore
import UIKit

/**
 A class that wraps an Element and adds a `paramsUpdater` closure, provided at initialization, used to implement `PaymentMethodElement.updateParams`
 
 This exists because `IntentConfirmParams` is a type specific to `StripePaymentSheet`, whereas `Element` is shared
 */
class PaymentMethodElementWrapper<WrappedElementType: Element> {
    typealias DefaultsApplier = (WrappedElementType, IntentConfirmParams) -> IntentConfirmParams
    typealias ParamsUpdater = (WrappedElementType, IntentConfirmParams) -> IntentConfirmParams?

    let element: WrappedElementType
    weak var delegate: ElementDelegate?

    // MARK: IntentConfirmParams updating glue
    let defaultsApplier: DefaultsApplier?
    let paramsUpdater: ParamsUpdater

    /**
     This only exists as a workaround to make initializers with a specific Element type e.g. TextFieldElement.
     */
    fileprivate init(
        privateElement element: WrappedElementType,
        defaultsApplier: DefaultsApplier? = nil,
        paramsUpdater: @escaping ParamsUpdater
    ) {
        self.element = element
        self.defaultsApplier = defaultsApplier
        self.paramsUpdater = paramsUpdater
        element.delegate = self
    }

    convenience init(
        _ element: WrappedElementType,
        defaultsApplier: DefaultsApplier? = nil,
        paramsUpdater: @escaping ParamsUpdater
    ) {
        self.init(privateElement: element, defaultsApplier: defaultsApplier, paramsUpdater: paramsUpdater)
    }

    convenience init(
        _ element: TextFieldElement,
        defaultsApplier: DefaultsApplier? = nil,
        paramsUpdater: @escaping ParamsUpdater
    ) where WrappedElementType == TextFieldElement {
        self.init(privateElement: element, defaultsApplier: defaultsApplier) { textField, params in
            guard case .valid = textField.validationState else {
                return nil
            }
            return paramsUpdater(textField, params)
        }
    }
    convenience init(
        _ textFieldElementConfiguration: TextFieldElementConfiguration,
        theme: ElementsAppearance,
        defaultsApplier: DefaultsApplier? = nil,
        paramsUpdater: @escaping ParamsUpdater
    ) where WrappedElementType == TextFieldElement {
        let textFieldElement = TextFieldElement(configuration: textFieldElementConfiguration, theme: theme)
        self.init(textFieldElement, defaultsApplier: defaultsApplier, paramsUpdater: paramsUpdater)
    }

    public var debugDescription: String {
        return String(describing: element)
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
    var collectsUserInput: Bool {
        return element.collectsUserInput
    }

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

extension Element {
    /// A convenience method that returns this element plus any children elements if this is a `ContainerElement`.
    /// Automatically unwraps any Elements wrapped in `PaymentMethodElementWrapper`.
    public func getAllUnwrappedSubElements() -> [Element] {
        switch self {
        case let wrapper as AnyPaymentMethodElementWrapper:
            return wrapper.anyElement.getAllUnwrappedSubElements()
        case let container as ContainerElement:
            return [container] + container.elements.flatMap { $0.getAllUnwrappedSubElements() }
        default:
            return [self]
        }
    }
}

/// Helper protocol easily switch over `PaymentMethodElementWrapper`
private protocol AnyPaymentMethodElementWrapper {
    var anyElement: Element { get }
}

extension PaymentMethodElementWrapper: AnyPaymentMethodElementWrapper {
    var anyElement: Element {
        return element
    }
}
