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
        guard let paymentMethodType = PaymentSheet.PaymentMethodType.string(from: paymentMethod) else {
            return nil
        }
        return provider.formSpec(for: paymentMethodType)
    }

    func makeFormElementFromSpec(spec: FormSpec) -> FormElement {
        let elements = makeFormElements(from: spec)
        return FormElement(autoSectioningElements: elements, theme: theme)
    }

    private func makeFormElements(from spec: FormSpec) -> [Element] {
        var elements: [Element] = []
        for fieldSpec in spec.fields {
            if let element = fieldSpecToElement(fieldSpec: fieldSpec) {
                elements.append(element)
            }
        }
        return elements
    }

    private func fieldSpecToElement(fieldSpec: FormSpec.FieldSpec) -> Element? {
        switch fieldSpec {
        case .name(let spec):
            return makeName(label: spec.translationId?.localizedValue, apiPath: spec.apiPath?["v1"])
        case .email(let spec):
            return makeEmail(apiPath: spec.apiPath?["v1"])
        case .selector(let selectorSpec):
            let dropdownItems: [DropdownFieldElement.DropdownItem] = selectorSpec.items.map {
                .init(pickerDisplayName: $0.displayText, labelDisplayName: $0.displayText, accessibilityLabel: $0.displayText, rawData: $0.apiValue ?? $0.displayText)
            }
            let dropdownField = DropdownFieldElement(
                items: dropdownItems,
                label: selectorSpec.translationId.localizedValue,
                theme: theme
            )
            return PaymentMethodElementWrapper(dropdownField) { dropdown, params in
                let selectedValue = dropdown.selectedItem.rawData
                //TODO: Determine how to handle multiple versions
                if let apiPathKey = selectorSpec.apiPath?["v1"] {
                    params.paymentMethodParams.additionalAPIParameters[apiPathKey] = selectedValue
                }
                return params
            }
        case .billing_address(let countrySpec):
            return makeBillingAddressSection(countries: countrySpec.allowedCountryCodes)
        case .country(let spec):
            return makeCountry(countryCodes: spec.allowedCountryCodes, apiPath: spec.apiPath?["v1"])
        case .affirm_header:
            return StaticElement(view: AffirmCopyLabel(theme: theme))
        case .klarna_header:
            return makeKlarnaCopyLabel()
        case .klarna_country(let spec):
            return makeKlarnaCountry(apiPath: spec.apiPath?["v1"])!
        case .au_becs_bsb_number(let spec):
            return makeBSB(apiPath: spec.apiPath?["v1"])
        case .au_becs_account_number(let spec):
            return makeAUBECSAccountNumber(apiPath: spec.apiPath?["v1"])
        case .au_becs_mandate:
            return makeAUBECSMandate()
        case .afterpay_header:
            return makeAfterpayClearpayHeader()!
        case .iban(let spec):
            return makeIban(apiPath: spec.apiPath?["v1"])
        case .sepa_mandate:
            return makeSepaMandate()
        case .unknown:
            return nil
        }
    }
}
