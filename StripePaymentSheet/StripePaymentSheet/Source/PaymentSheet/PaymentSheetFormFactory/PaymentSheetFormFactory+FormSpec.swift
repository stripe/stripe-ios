//
//  PaymentSheetFormFactory+FormSpec.swift
//  StripePaymentSheet
//
//  Created by Yuki Tokuhiro on 2/15/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation
import StripeCore
@_spi(STP) import StripeUICore

extension PaymentSheetFormFactory {
    func specFromJSONProvider(provider: FormSpecProvider = FormSpecProvider.shared) -> FormSpec? {
        guard let paymentMethodType = PaymentSheet.PaymentMethodType.string(from: paymentMethod) else {
            return nil
        }
        return provider.formSpec(for: paymentMethodType)
    }

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
            if let element = fieldSpecToElement(fieldSpec: fieldSpec) {
                // Check if this is a billing details field and process it.
                switch fieldSpec {
                case .name:
                    billingDetailsFields.remove(.name)
                case .email:
                    billingDetailsFields.remove(.email)
                case .billing_address:
                    billingDetailsFields.remove(.billingAddress)
                    billingAddressElement = element
                case .country, .klarna_country:
                    countryElement = element
                case .placeholder(let placeholder):
                    switch placeholder.field {
                    case .name:
                        billingDetailsFields.remove(.name)
                    case .email:
                        billingDetailsFields.remove(.email)
                    case .phone:
                        billingDetailsFields.remove(.phone)
                        phoneElement = element
                    case .billingAddress, .billingAddressWithoutCountry:
                        billingDetailsFields.remove(.billingAddress)
                        billingAddressElement = element
                    default: break
                    }
                default: break
                }

                elements.append(element)
            }
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
            countryElement: countryElement,
            addressElement: billingAddressElement,
            phoneElement: phoneElement)

        return elements
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
            let dropdownItems: [DropdownFieldElement.DropdownItem] = selectorSpec.items.map {
                .init(pickerDisplayName: $0.displayText, labelDisplayName: $0.displayText, accessibilityValue: $0.displayText, rawData: $0.apiValue ?? $0.displayText)
            }
            let dropdownField = DropdownFieldElement(
                items: dropdownItems,
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
        case .billing_address(let countrySpec):
            return configuration.billingDetailsCollectionConfiguration.address != .never
                ? makeBillingAddressSection(countries: countrySpec.allowedCountryCodes)
                : nil
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

    private func connectBillingDetailsFields(
        countryElement: Element?,
        addressElement: Element?,
        phoneElement: Element?
    ) {
        // Using a closure because a function would require capturing self, which will be deallocated by the time
        // the closures below are called.
        let defaultBillingDetails = configuration.defaultBillingDetails
        let updatePhone = { (phoneElement: PhoneNumberElement, countryCode: String) in
            // Only update the phone country if:
            // 1. It's different from the selected one,
            // 2. A default phone number was not provided.
            // 3. The phone field hasn't been modified yet.
            guard countryCode != phoneElement.selectedCountryCode
                    && defaultBillingDetails.phone == nil
                    && !phoneElement.hasBeenModified
            else {
                return
            }

            phoneElement.selectedCountryCode = countryCode
        }

        if let countryElement = countryElement as? PaymentMethodElementWrapper<DropdownFieldElement> {
            countryElement.element.didUpdate = { [updatePhone] _ in
                let countryCode = countryElement.element.selectedItem.rawData
                if let phoneElement = phoneElement as? PaymentMethodElementWrapper<PhoneNumberElement> {
                    updatePhone(phoneElement.element, countryCode)
                }
                if let addressElement = addressElement as? PaymentMethodElementWrapper<AddressSectionElement> {
                    addressElement.element.selectedCountryCode = countryCode
                }
            }

            if let addressElement = addressElement as? PaymentMethodElementWrapper<AddressSectionElement>,
               addressElement.element.selectedCountryCode != countryElement.element.selectedItem.rawData
            {
                addressElement.element.selectedCountryCode = countryElement.element.selectedItem.rawData
            }
        }

        if let addressElement = addressElement as? PaymentMethodElementWrapper<AddressSectionElement> {
            addressElement.element.didUpdate = { [updatePhone] addressDetails in
                if let countryCode = addressDetails.address.country,
                   let phoneElement = phoneElement as? PaymentMethodElementWrapper<PhoneNumberElement>
                {
                    updatePhone(phoneElement.element, countryCode)
                }
            }
        }
    }
}
