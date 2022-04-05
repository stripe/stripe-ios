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
        return spec.elements.map { elementSpec in
            switch elementSpec {
            case .name:
                return makeFullName()
            case .email:
                return makeEmail()
            case .customDropdown(let dropdownSpec):
                let dropdownField = DropdownFieldElement(
                    items: dropdownSpec.dropdownItems.map { $0.localizedDisplayText },
                    label: dropdownSpec.label.localizedValue
                )
                return PaymentMethodElementWrapper(dropdownField) { dropdown, params in
                    let values = dropdownSpec.dropdownItems.map { $0.apiValue }
                    let selectedValue = values[dropdown.selectedIndex]
                    params.paymentMethodParams.additionalAPIParameters[dropdownSpec.paymentMethodDataPath] = selectedValue
                    return params
                }
            }
        }
    }
}
