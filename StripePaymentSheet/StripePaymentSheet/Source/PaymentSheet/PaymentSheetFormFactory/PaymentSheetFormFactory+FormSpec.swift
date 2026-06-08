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
    private typealias NativePaymentMethodFormBuilder = (PaymentSheetFormFactory, FormSpec.NativePaymentMethodFormSpec) -> PaymentMethodElement
    private typealias NativeMandateBuilder = (PaymentSheetFormFactory) -> Element

    private static let nativePaymentMethodFormBuilders: [FormSpec.NativePaymentMethodFormSpec.FormType: NativePaymentMethodFormBuilder] = [
        .card: { factory, _ in factory.makeCard(linkAppearance: factory.linkAppearance) },
        .usBankAccount: { factory, _ in factory.makeUSBankAccount(merchantName: factory.configuration.merchantDisplayName) },
        .instantDebits: { factory, _ in factory.makeInstantDebits() },
        .externalPaymentMethod: { factory, spec in
            factory.makeExternalPaymentMethodForm(
                subtitle: spec.subtitle,
                disableBillingDetailCollection: spec.disableBillingDetailCollection ?? false
            )
        },
        .bacsDebit: { factory, _ in factory.makeBacsDebit() },
        .blik: { factory, _ in factory.makeBLIK() },
        .konbini: { factory, _ in factory.makeKonbini() },
        .boleto: { factory, _ in factory.makeBoleto() },
    ]

    private static let nativeMandateBuilders: [FormSpec.NativeMandateSpec.MandateType: NativeMandateBuilder] = [
        .cashApp: { factory in factory.makeCashAppMandate() },
        .paypal: { factory in factory.makePaypalMandate() },
        .revolutPay: { factory in factory.makeRevolutPayMandate() },
        .amazonPay: { factory in factory.makeAmazonPayMandate() },
        .satispay: { factory in factory.makeSatispayMandate() },
        .twint: { factory in factory.makeTwintMandate() },
        .sepa: { factory in factory.makeSepaMandate() },
        .klarna: { factory in factory.makeKlarnaMandate() },
    ]

    func makeFormElementFromSpec(
        spec: FormSpec,
        additionalElements: [Element] = []
    ) -> PaymentMethodElementWrapper<FormElement> {
        let elements = makeFormElements(from: spec)
        let formElement = FormElement(
            autoSectioningElements: elements + additionalElements,
            theme: theme
        )
        return makeDefaultsApplierWrapper(for: formElement)
    }

    private func makeFormElements(from spec: FormSpec) -> [Element] {
        // These fields will need to be connected.
        var countryElement: Element?
        var billingAddressElement: Element?
        var phoneElement: Element?

        var elements: [Element] = []
        for fieldSpec in spec.fields {
            guard let element = fieldSpecToElement(fieldSpec: fieldSpec) else { continue }

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

        connectBillingDetailsFields(
            countryElement: countryElement as? PaymentMethodElementWrapper<DropdownFieldElement>,
            addressElement: billingAddressElement as? PaymentMethodElementWrapper<AddressSectionElement>,
            phoneElement: phoneElement as? PaymentMethodElementWrapper<PhoneNumberElement>
        )

        return elements
    }

    private func fieldSpecToElement(fieldSpec: FormSpec.FieldSpec) -> Element? {
        switch fieldSpec {
        case let .name(spec):
            return configuration.billingDetailsCollectionConfiguration.name != .never
                ? makeName(label: spec.translationId?.localizedValue, apiPath: spec.apiPath?["v1"])
                : nil
        case let .email(spec):
            return configuration.billingDetailsCollectionConfiguration.email != .never
                ? makeEmail(apiPath: spec.apiPath?["v1"])
                : nil
        case let .selector(selectorSpec):
            return makeDropdown(for: selectorSpec)
        case let .billing_address(countrySpec):
            return configuration.billingDetailsCollectionConfiguration.address != .never
                ? makeBillingAddressSection(countries: countrySpec.allowedCountryCodes)
                : nil
        case let .country(spec):
            return makeCountry(countryCodes: spec.allowedCountryCodes, apiPath: spec.apiPath?["v1"])
        case .affirm_header:
            return makeAffirmHeader()
        case .klarna_header:
            return makeKlarnaHeader()
        case let .klarna_country(spec):
            return makeKlarnaCountry(apiPath: spec.apiPath?["v1"])!
        case let .au_becs_bsb_number(spec):
            return makeBSB(apiPath: spec.apiPath?["v1"])
        case let .au_becs_account_number(spec):
            return makeAUBECSAccountNumber(apiPath: spec.apiPath?["v1"])
        case .au_becs_mandate:
            return makeAUBECSMandate()
        case .afterpay_header:
            return makeAfterpayClearpayHeader()
        case let .iban(spec):
            return makeIban(apiPath: spec.apiPath?["v1"])
        case .sepa_mandate:
            return makeSepaMandate()
        case let .placeholder(spec):
            return makePlaceholder(for: spec)
        case let .native_payment_method_form(spec):
            return makeNativePaymentMethodForm(for: spec)
        case let .native_mandate(spec):
            return makeNativeMandate(for: spec)
        case let .unknown(fieldType):
            logUnsupportedFormSpecField(fieldType)
            return nil
        }
    }

    private func logUnsupportedFormSpecField(_ fieldType: String) {
        let errorAnalytic = ErrorAnalytic(
            event: .unexpectedPaymentSheetFormFactoryError,
            error: Error.unsupportedFormSpecField,
            additionalNonPIIParams: [
                "payment_method": paymentMethod.identifier,
                "field_type": fieldType,
            ]
        )
        analyticsHelper?.analyticsClient.log(analytic: errorAnalytic)

        let assertMessage = "Unsupported PaymentSheet form spec field '\(fieldType)' for \(paymentMethod.identifier)"
        print("STPAssertionFailure: \(assertMessage)")
    }

    func makeNativePaymentMethodForm(for spec: FormSpec.NativePaymentMethodFormSpec) -> PaymentMethodElement? {
        return Self.nativePaymentMethodFormBuilders[spec.formType]?(self, spec)
    }

    func makeNativeMandate(for spec: FormSpec.NativeMandateSpec) -> Element? {
        if spec.setupFutureUsageRequired == true && !isSettingUp {
            return nil
        }

        return Self.nativeMandateBuilders[spec.mandateType]?(self)
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
                ? makeBillingAddressSection(countries: configuration.billingDetailsCollectionConfiguration.allowedCountriesArray)
                : nil
        case .billingAddressWithoutCountry:
            return configuration.billingDetailsCollectionConfiguration.address == .full
                ? makeBillingAddressSection(collectionMode: .noCountry, countries: configuration.billingDetailsCollectionConfiguration.allowedCountriesArray)
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
        if case let .placeholder(placeholderSpec) = self {
            return placeholderSpec.field == .phone
        }
        return false
    }

    var isAddressSpec: Bool {
        switch self {
        case .billing_address: return true
        case let .placeholder(placeholderSpec):
            switch placeholderSpec.field {
            case .billingAddress, .billingAddressWithoutCountry: return true
            default: break
            }
        default: break
        }

        return false
    }
}

extension FormSpec {
    var nativePaymentMethodFormSpec: NativePaymentMethodFormSpec? {
        guard fields.count == 1,
              case let .native_payment_method_form(spec) = fields.first
        else {
            return nil
        }
        return spec
    }
}
