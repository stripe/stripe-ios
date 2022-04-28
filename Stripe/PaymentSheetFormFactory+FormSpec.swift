//
//  PaymentSheetFormFactory+FormSpec.swift
//  StripeiOS
//
//  Created by Yuki Tokuhiro on 2/15/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeUICore

extension PaymentSheetFormFactory {
    func makeFormElementFromJSONSpecs() -> FormElement? {
        guard
            let paymentMethodType = STPPaymentMethod.string(from: paymentMethod),
            let formSpec = FormSpecProvider.shared.formSpec(for: paymentMethodType)
        else {
            return nil
        }
        let elements = makeFormElements(from: formSpec)
        let formElement = FormElement(autoSectioningElements: elements)
        return formElement
    }
    
    private func makeFormElements(from spec: FormSpec) -> [Element] {
        return spec.fields.map { elementSpec in
            switch elementSpec {
            case .name:
                return makeFullName()
            case .email:
                return makeEmail()
            case .selector(let selectorSpec):
                let dropdownField = DropdownFieldElement(
                    items: selectorSpec.property.items.map { $0.displayText },
                    label: selectorSpec.property.label.localizedValue
                )
                return PaymentMethodElementWrapper(dropdownField) { dropdown, params in
                    let values = selectorSpec.property.items.map { $0.apiValue }
                    let selectedValue = values[dropdown.selectedIndex]
                    params.paymentMethodParams.additionalAPIParameters[selectorSpec.property.apiKey] = selectedValue
                    return params
                }
            }
        }
    }
}
