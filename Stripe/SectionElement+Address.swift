//
//  SectionElement+Address.swift
//  StripeiOS
//
//  Created by Yuki Tokuhiro on 7/19/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore

extension Locale {
    /// Returns the given array of country/region codes sorted alphabetically by their localized display names
    func sortedByTheirLocalizedNames(_ regionCodes: [String]) -> [String] {
        return regionCodes.sorted {
            (localizedString(forRegionCode: $0) ?? $0) < localizedString(forRegionCode: $1) ?? $1
        }
    }
}

extension SectionElement {
    static func makeBillingAddress(
        locale: Locale = .current,
        addressSpecProvider: AddressSpecProvider = .shared,
        defaults: PaymentSheet.Address = .init()
    ) -> SectionElement {
        let countryCodes = locale.sortedByTheirLocalizedNames(addressSpecProvider.countries)
        let country = PaymentMethodElementWrapper(DropdownFieldElement(
            label: String.Localized.country_or_region,
            countryCodes: countryCodes,
            defaultCountry: defaults.country
        )) { dropdown, params in
            params.paymentMethodParams.nonnil_billingDetails.nonnil_address.country = countryCodes[dropdown.selectedIndex]
            return params
        }
        let initialAddressFields = addressFields(
            for: countryCodes[country.element.selectedIndex],
            addressSpecProvider: addressSpecProvider,
            defaults: defaults
        )
        let section = SectionElement(
            title: String.Localized.billing_address,
            elements: [country] + initialAddressFields
        )
        country.element.didUpdate = { [weak section] index in
            // Change the billing fields to reflect the new country
            let addressFields = addressFields(
                for: countryCodes[index],
                addressSpecProvider: addressSpecProvider,
                defaults: defaults
            )
            section?.elements = [country] + addressFields
        }
        return section
    }
    
    // MARK: - Parse from format

    static func addressFields(
        for country: String,
        addressSpecProvider: AddressSpecProvider = .shared,
        defaults: PaymentSheet.Address = .init()
    ) -> [PaymentMethodElementWrapper<TextFieldElement>] {
        let spec = addressSpecProvider.addressSpec(for: country)
        let format = spec.format
        return format.reduce([]) { partialResult, char in
            switch char {
            case "A": // Address lines
                let line1 = makeLine1(defaultValue: defaults.line1)
                let line2 = makeLine2(defaultValue: defaults.line2)
                return partialResult + [line1, line2]
            case "C": // City
                let label = spec.cityNameType.localizedLabel
                let city = PaymentMethodElementWrapper(TextFieldElement(
                    configuration: Address.CityConfiguration(label: label, defaultValue: defaults.city)
                )) { textField, params in
                    params.paymentMethodParams.nonnil_billingDetails.nonnil_address.city = textField.text
                    return params
                }
                city.element.isOptional = !spec.require.contains("C")
                return partialResult + [city]
            case "S": // State
                let label = spec.stateNameType.localizedLabel
                let state = PaymentMethodElementWrapper(TextFieldElement(
                    configuration: Address.StateConfiguration(label: label, defaultValue: defaults.state)
                )) { textField, params in
                    params.paymentMethodParams.nonnil_billingDetails.nonnil_address.state = textField.text
                    return params
                }
                state.element.isOptional = !spec.require.contains("S")
                return partialResult + [state]
            case "Z": // Postal/Zip
                let label = spec.zipNameType.localizedLabel
                let regex = spec.zip
                let config = Address.PostalCodeConfiguration(regex: regex, label: label, defaultValue: defaults.postalCode)
                let postal = PaymentMethodElementWrapper(TextFieldElement(
                    configuration: config
                )) { textField, params in
                    params.paymentMethodParams.nonnil_billingDetails.nonnil_address.postalCode = textField.text
                    return params
                }
                postal.element.isOptional = !spec.require.contains("Z")
                return partialResult + [postal]
            default:
                return partialResult
            }
        }
    }
    
    fileprivate typealias Address = TextFieldElement.Address
    
    fileprivate static func makeLine1(defaultValue: String?) -> PaymentMethodElementWrapper<TextFieldElement> {
        let config = Address.LineConfiguration(lineType: .line1, defaultValue: defaultValue)
        let line1 = TextFieldElement(configuration: config)
        return PaymentMethodElementWrapper(line1) { textField, params in
            params.paymentMethodParams.nonnil_billingDetails.nonnil_address.line1 = textField.text
            return params
        }
    }
    
    fileprivate static func makeLine2(defaultValue: String?) -> PaymentMethodElementWrapper<TextFieldElement> {
        let config = Address.LineConfiguration(lineType: .line2, defaultValue: defaultValue)
        let line2 = TextFieldElement(configuration: config)
        line2.isOptional = true // Hardcode all line2 as optional
        return PaymentMethodElementWrapper(line2) { textField, params in
            params.paymentMethodParams.nonnil_billingDetails.nonnil_address.line2 = textField.text
            return params
        }
    }
}

extension STPPaymentMethodBillingDetails {
    var nonnil_address: STPPaymentMethodAddress {
        guard let address = address else {
            let address = STPPaymentMethodAddress()
            self.address = address
            return address
        }
        return address
    }
}
