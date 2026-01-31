//
//  PaymentMethodElement.swift
//  StripePaymentSheet
//
//  Created by Yuki Tokuhiro on 9/14/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation
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

// MARK: - PaymentMethodElement utilities
/// Utility methods for working with PaymentMethodElements
enum PaymentMethodElementUtils {
    /// Clears all text fields within an element hierarchy
    static func clearTextFields(in element: Element) {
        for element in element.getAllUnwrappedSubElements() {
            if let element = element as? TextFieldElement {
                element.setText("")
            } else if let element = element as? CVCRecollectionElement {
                element.clearTextFields()
            }
        }
    }

    /// Get the mandate text from an element hierarchy, if available
    /// - Note: Assumes mandates are SimpleMandateElement
    static func getMandateText(from element: Element) -> NSAttributedString? {
        guard let mandateText = element.getAllUnwrappedSubElements()
            .compactMap({ $0 as? SimpleMandateElement })
            .first?.mandateTextView.attributedText,
              !mandateText.string.isEmpty else {
            return nil
        }
        return mandateText
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

// MARK: - Helpers

extension PaymentMethodElement {
    // Get the mandate from the form, if available
    // 🙋‍♂️ Note: assumes mandates are SimpleMandateElement!
    func getMandateText() -> NSAttributedString? {
        guard let mandateText = getAllUnwrappedSubElements().compactMap({ $0 as? SimpleMandateElement }).first?.mandateTextView.attributedText, !mandateText.string.isEmpty else {
            return nil
        }
        return mandateText
    }
}
