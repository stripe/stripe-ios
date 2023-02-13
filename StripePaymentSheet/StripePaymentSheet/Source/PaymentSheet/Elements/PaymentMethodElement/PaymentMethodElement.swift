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
 
 - Remark:In practice, only "leaf" Elements - text fields, drop downs, etc. - have any user data to update params with. These elements can be wrapped in `PaymentMethodElementWrapper`.
 Other elements can rely on the default implementation provided in this file.
 */
protocol PaymentMethodElement: Element {
    /// Modify the params with default values.
    ///
    /// This method is called before `updateParams(params:)` and should be used to populate `params` with any necessary
    /// default values, these can include values for fields not included in the element hierarchy.
    func applyDefaults(params: IntentConfirmParams) -> IntentConfirmParams

    /// Modify the params according to your input, or return nil if invalid.
    /// - Note: This is called on the Element hierarchy in depth-first search order.
    func updateParams(params: IntentConfirmParams) -> IntentConfirmParams?
}

// MARK: - Default implementations
extension ContainerElement {
    func applyDefaults(params: IntentConfirmParams) -> IntentConfirmParams {
        applyDefaultsHierarchichally(params: params)
    }

    func applyDefaultsHierarchichally(params: IntentConfirmParams) -> IntentConfirmParams {
        return elements.filter({ $0.view.isHidden == false })
            .reduce(params) { (params: IntentConfirmParams, element: Element) in
                switch element {
                case let element as PaymentMethodElement:
                    return element.applyDefaults(params: params)
                case let element as ContainerElement:
                    return element.applyDefaults(params: params)
                default:
                    return params
                }
            }
    }

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

extension FormElement: PaymentMethodElement {
    func applyDefaults(params: IntentConfirmParams) -> IntentConfirmParams {
        applyDefaultsHierarchichally(params: params)
    }
}

extension SectionElement: PaymentMethodElement {
    func applyDefaults(params: IntentConfirmParams) -> IntentConfirmParams {
        applyDefaultsHierarchichally(params: params)
    }
}

extension StaticElement: PaymentMethodElement {
    func applyDefaults(params: IntentConfirmParams) -> IntentConfirmParams {
        return params
    }

    func updateParams(params: IntentConfirmParams) -> IntentConfirmParams? {
        return params
    }
}

extension PaymentMethodElement {
    func applyDefaults(params: IntentConfirmParams) -> IntentConfirmParams { params }
}
