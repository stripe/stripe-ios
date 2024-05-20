//
//  PaymentMethodElement.swift
//  StripePaymentSheet
//
//  Created by Yuki Tokuhiro on 9/14/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

@_spi(STP) import StripeUICore

// MARK: - PaymentMethodElement protocol
/**
 This allows a user of an Element to collect all fields in the Element hierarchy into an instance of `IntentConfirmParams`.
 This exists separate from `Element` because `IntentConfirmParams` is a type specific to `StripePaymentSheet`, whereas `Element` is shared
 across modules that don't have this type.
 
 - Remark:In practice, only "leaf" Elements - text fields, drop downs, etc. - have any user data to update params with. These elements can be wrapped in `PaymentMethodElementWrapper`.
 Other elements can rely on the default implementation provided in this file.
 */
protocol PaymentMethodElement: Element {
    /// Modify the params according to your input, or return nil if invalid.
    /// - Note: This is called on the Element hierarchy in depth-first search order.
    func updateParams(params: IntentConfirmParams) -> IntentConfirmParams?
}

extension PaymentMethodElement {
    func clearTextFields() {
        for element in getAllUnwrappedSubElements() {
            if let element = element as? TextFieldElement {
                element.setText("")
            } else if let element = element as? CVCRecollectionElement {
                element.clearTextFields()
            }
        }
    }
}

// MARK: - Default implementations
extension ContainerElement {
    func updateParams(params: IntentConfirmParams) -> IntentConfirmParams? {
        return elements.filter({ $0.view.isHidden == false })
            .reduce(params) { (params: IntentConfirmParams?, element: Element) in
                guard let params = params else {
                    return nil
                }
                switch element {
                case let element as PaymentMethodElement:
                    return element.updateParams(params: params)
                case let element as ContainerElement:
                    return element.updateParams(params: params)
                default:
                    return params
                }
            }
    }
}

extension FormElement: PaymentMethodElement {}

extension SectionElement: PaymentMethodElement {}

extension StaticElement: PaymentMethodElement {
    func updateParams(params: IntentConfirmParams) -> IntentConfirmParams? {
        return params
    }
}
