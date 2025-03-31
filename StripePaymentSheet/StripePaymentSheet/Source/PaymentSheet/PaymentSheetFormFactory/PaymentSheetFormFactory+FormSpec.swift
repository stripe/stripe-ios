//
//  PaymentSheetFormFactory+FormSpec.swift
//  StripePaymentSheet
//
//  Created by Yuki Tokuhiro on 2/15/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore

extension PaymentSheetFormFactory {
    func makeFormElementFromSpec(
        spec: FormSpec,
        additionalElements: [Element] = []
    ) -> PaymentMethodElementWrapper<FormElement> {
        let elements = makeFormElements(from: spec)
        let formElement = FormElement(
            autoSectioningElements: elements + additionalElements,
            theme: theme)
        return makeDefaultsApplierWrapper(for: formElement)
    }

    private func makeFormElements(from spec: FormSpec) -> [Element] {
        // These fields may be added according to `configuration.billingDetailsCollectionConfiguration` if they
        // aren't already present.
        var billingDetailsFields: [FormSpec.PlaceholderSpec.PlaceholderField] = [
            .name,
            .email,
            .phone,
            .billingAddress,
        ]

        // These fields will need to be connected.
        var countryElement: Element?
        var billingAddressElement: Element?
        var phoneElement: Element?

        var elements: [Element] = []
        for fieldSpec in spec.fields {
            guard let element = fieldSpecToElement(fieldSpec: fieldSpec) else { continue }
            if let fieldToRemove = fieldToRemove(from: fieldSpec) {
                billingDetailsFields.remove(fieldToRemove)
            }

            if fieldSpec.isCountrySpec {
                countryElement = element
            }
            if fieldSpec.isPhoneSpec {
                phoneElement = element
            }
            if fieldSpec.isAddressSpec {
                billingAddressElement = element
            }

            elements.append(element)
        }

        // Add billing details fields if they are needed and not already present.
        for field in billingDetailsFields {
            guard let element = makeOptionalBillingDetailsField(for: field) else { continue }

            switch field {
            case .phone:
                phoneElement = element
            case .billingAddress:
                billingAddressElement = element
            default: break
            }

            elements.append(element)
        }

        connectBillingDetailsFields(
            countryElement: countryElement as? PaymentMethodElementWrapper<DropdownFieldElement>,
            addressElement: billingAddressElement as? PaymentMethodElementWrapper<AddressSectionElement>,
            phoneElement: phoneElement as? PaymentMethodElementWrapper<PhoneNumberElement>)

        return elements
    }

    private func fieldToRemove(from fieldSpec: FormSpec.FieldSpec) -> FormSpec.PlaceholderSpec.PlaceholderField? {
        switch fieldSpec {
        case .name:
            return .name
        case .email:
            return .email
        case .billing_address:
            return .billingAddress
        case .placeholder(let placeholder):
            switch placeholder.field {
            case .name:
                return .name
            case .email:
                return .email
            case .phone:
                return .phone
            case .billingAddress, .billingAddressWithoutCountry:
                return .billingAddress
            default: return nil
            }
        default: return nil
        }
    }

    private func fieldSpecToElement(fieldSpec: FormSpec.FieldSpec) -> Element? {
        switch fieldSpec {
        case .name(let spec):
            return configuration.billingDetailsCollectionConfiguration.name != .never
                ? makeName(label: spec.translationId?.localizedValue, apiPath: spec.apiPath?["v1"])
                : nil
        case .email(let spec):
            return configuration.billingDetailsCollectionConfiguration.email != .never
                ? makeEmail(apiPath: spec.apiPath?["v1"])
                : nil
        case .selector(let selectorSpec):
            return makeDropdown(for: selectorSpec)
        case .billing_address(let countrySpec):
            return configuration.billingDetailsCollectionConfiguration.address != .never
                ? makeBillingAddressSection(countries: countrySpec.allowedCountryCodes)
                : nil
        case .country(let spec):
            return makeCountry(countryCodes: spec.allowedCountryCodes, apiPath: spec.apiPath?["v1"])
        case .affirm_header:
            return SubtitleElement(view: AffirmCopyLabel(theme: theme), isHorizontalMode: configuration.isHorizontalMode)
        case .klarna_header:
            return makeCopyLabel(text: .Localized.buy_now_or_pay_later_with_klarna)
        case .klarna_country(let spec):
            return makeKlarnaCountry(apiPath: spec.apiPath?["v1"])!
        case .au_becs_bsb_number(let spec):
            return makeBSB(apiPath: spec.apiPath?["v1"])
        case .au_becs_account_number(let spec):
            return makeAUBECSAccountNumber(apiPath: spec.apiPath?["v1"])
        case .au_becs_mandate:
            return makeAUBECSMandate()
        case .afterpay_header:
            return makeAfterpayClearpayHeader()
        case .iban(let spec):
            return makeIban(apiPath: spec.apiPath?["v1"])
        case .sepa_mandate:
            return makeSepaMandate()
        case .placeholder(let spec):
            return makePlaceholder(for: spec)
        case .unknown:
            return nil
        }
    }

    func makePlaceholder(for spec: FormSpec.PlaceholderSpec) -> Element? {
        let field = spec.field
        guard field != .unknown else { return nil }
        return makeOptionalBillingDetailsField(for: field)
    }

    func makeOptionalBillingDetailsField(for field: FormSpec.PlaceholderSpec.PlaceholderField) -> Element? {
        switch field {
        case .name:
            return configuration.billingDetailsCollectionConfiguration.name == .always ? makeName() : nil
        case .email:
            return configuration.billingDetailsCollectionConfiguration.email == .always ? makeEmail() : nil
        case .phone:
            return configuration.billingDetailsCollectionConfiguration.phone == .always ? makePhone() : nil
        case .billingAddress:
            return configuration.billingDetailsCollectionConfiguration.address == .full
                ? makeBillingAddressSection(countries: nil)
                : nil
        case .billingAddressWithoutCountry:
            return configuration.billingDetailsCollectionConfiguration.address == .full
                ? makeBillingAddressSection(collectionMode: .noCountry, countries: nil)
                : nil
        case .unknown: return nil
        }
    }

    func makeDropdown(for selectorSpec: FormSpec.SelectorSpec) -> PaymentMethodElementWrapper<DropdownFieldElement> {
        if selectorSpec.apiPath?["v1"] == nil {
            let errorAnalytic = ErrorAnalytic(event: .unexpectedPaymentSheetFormFactoryError,
                                              error: Error.missingV1FromSelectorSpec,
                                              additionalNonPIIParams: ["payment_method": paymentMethod.identifier])
            analyticsHelper?.analyticsClient.log(analytic: errorAnalytic)
        }
        stpAssert(selectorSpec.apiPath?["v1"] != nil) // If there's no api path, the dropdown selection is unused!
        let dropdownItems: [DropdownFieldElement.DropdownItem] = selectorSpec.items.map {
            .init(pickerDisplayName: $0.displayText, labelDisplayName: $0.displayText, accessibilityValue: $0.displayText, rawData: $0.apiValue ?? $0.displayText)
        }
        let previousCustomerInputIndex = dropdownItems.firstIndex { item in
            item.rawData == getPreviousCustomerInput(for: selectorSpec.apiPath?["v1"])
        }
        let dropdownField = DropdownFieldElement(
            items: dropdownItems,
            defaultIndex: previousCustomerInputIndex ?? 0,
            label: selectorSpec.translationId.localizedValue,
            theme: theme
        )
        return PaymentMethodElementWrapper(dropdownField) { dropdown, params in
            let selectedValue = dropdown.selectedItem.rawData
            // TODO: Determine how to handle multiple versions
            if let apiPathKey = selectorSpec.apiPath?["v1"] {
                params.paymentMethodParams.additionalAPIParameters[apiPathKey] = selectedValue
            }
            return params
        }
    }
}

extension FormSpec.FieldSpec {
    var isCountrySpec: Bool {
        switch self {
        case .country, .klarna_country: return true
        default: return false
        }
    }

    var isPhoneSpec: Bool {
        if case .placeholder(let placeholderSpec) = self {
            return placeholderSpec.field == .phone
        }
        return false
    }

    var isAddressSpec: Bool {
        switch self {
        case .billing_address: return true
        case .placeholder(let placeholderSpec):
            switch placeholderSpec.field {
            case .billingAddress, .billingAddressWithoutCountry: return true
            default: break
            }
        default: break
        }

        return false
    }
}
