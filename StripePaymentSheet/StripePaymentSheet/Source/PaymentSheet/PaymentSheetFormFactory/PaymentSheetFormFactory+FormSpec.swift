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
        var billingAddressElement: Element?
        var phoneElement: Element?

        var elements: [Element] = []
        for fieldSpec in spec.fields {
            guard let element = fieldSpecToElement(fieldSpec: fieldSpec) else { continue }
            if let fieldToRemove = fieldToRemove(from: fieldSpec) {
                billingDetailsFields.remove(fieldToRemove)
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
        // Country fields produce an AddressSectionElement that also collects the full address when configured,
        // so suppress the auto-added billing address placeholder.
        case .billing_address, .country, .klarna_country:
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
            return makeBillingAddressSectionIfNecessary(fullAddressRequiredByPaymentMethod: true, allowedCountries: countrySpec.allowedCountryCodes)
        case .country(let spec):
            return makeCountryOrAddressSection(
                countries: spec.allowedCountryCodes,
                countryAPIPath: spec.apiPath?["v1"]
            )
        case .affirm_header:
            return makeAffirmHeader()
        case .klarna_header:
            return makeKlarnaHeader()
        case .klarna_country(let spec):
            return makeCountryOrAddressSection(
                countries: configuration.billingDetailsCollectionConfiguration.allowedCountriesArray,
                countryAPIPath: spec.apiPath?["v1"]
            )
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
            switch configuration.billingDetailsCollectionConfiguration.address {
            case .full:
                return makeBillingAddressSection(countries: configuration.billingDetailsCollectionConfiguration.allowedCountriesArray)
            case .automatic:
                // Only collect an address if the Checkout Session needs it to compute tax.
                guard collectsTaxFromBillingAddress else { return nil }
                return makeBillingAddressSection(
                    collectionMode: .countryOnly,
                    countryFieldsOverrides: CountryTaxRequirement.fieldsToCollectByCountry,
                    countries: configuration.billingDetailsCollectionConfiguration.allowedCountriesArray
                )
            case .never:
                stpAssert(!isCheckoutSession, "CheckoutSession does not support billingDetailsCollectionConfiguration.address = .never")
                return nil
            }
        case .billingAddressWithoutCountry:
            // The address (including country) is collected by the accompanying country /
            // klarna_country AddressSectionElement, so this placeholder produces nothing.
            return nil
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
    var isPhoneSpec: Bool {
        if case .placeholder(let placeholderSpec) = self {
            return placeholderSpec.field == .phone
        }
        return false
    }

    var isAddressSpec: Bool {
        switch self {
        // `.country` and `.klarna_country` produce an AddressSectionElement (country-only or full address)
        case .billing_address, .country, .klarna_country: return true
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
