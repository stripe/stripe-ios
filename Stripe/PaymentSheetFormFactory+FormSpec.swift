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

    func specFromJSONProvider(provider: FormSpecProvider = FormSpecProvider.shared) -> FormSpec? {
        guard let paymentMethodType = STPPaymentMethod.string(from: paymentMethod) else {
            return nil
        }
        return provider.formSpec(for: paymentMethodType)
    }

    func makeFormElementFromSpec(spec: FormSpec) -> FormElement {
        let elements = makeFormElements(from: spec)
        return FormElement(autoSectioningElements: elements)
    }

    private func makeFormElements(from spec: FormSpec) -> [Element] {
        return spec.fields.map { elementSpec in
            switch elementSpec {
            case .name(let spec):
                return makeFullName(apiPath: spec.apiPath?["v1"])
            case .email(let spec):
                return makeEmail(apiPath: spec.apiPath?["v1"])
            case .selector(let selectorSpec):
                let dropdownField = DropdownFieldElement(
                    items: selectorSpec.items.map { $0.displayText },
                    label: selectorSpec.label.localizedValue
                )
                return PaymentMethodElementWrapper(dropdownField) { dropdown, params in
                    let values = selectorSpec.items.map { $0.apiValue }
                    let selectedValue = values[dropdown.selectedIndex]
                    //TODO: Determine how to handle multiple versions
                    if let apiPathKey = selectorSpec.apiPath?["v1"] {
                        params.paymentMethodParams.additionalAPIParameters[apiPathKey] = selectedValue
                    }
                    return params
                }
            }
        }
    }
}
