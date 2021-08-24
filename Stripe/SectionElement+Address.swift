//
//  SectionElement+Address.swift
//  StripeiOS
//
//  Created by Yuki Tokuhiro on 7/19/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeCore

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
        let country = DropdownFieldElement(
            label: String.Localized.country_or_region,
            countryCodes: countryCodes,
            defaultCountry: defaults.country
        )
        let section = SectionElement(
            title: String.Localized.billing_address,
            elements: [country] + addressFields(for: countryCodes[country.selectedIndex], defaults: defaults)
        )
        country.didUpdate = { [weak section] index in
            // Change the billing fields to reflect the new country
            section?.elements = [country] + addressFields(for: countryCodes[index])
        }
        return section
    }
    
    // MARK: - Parse from format
    
    fileprivate typealias Address = TextFieldElement.Address
    
    static func addressFields(
        for country: String,
        addressSpecProvider: AddressSpecProvider = .shared,
        defaults: PaymentSheet.Address = .init()
    ) -> [TextFieldElement] {
        let spec = addressSpecProvider.addressSpec(for: country)
        let format = spec.format
        return format.reduce([]) { partialResult, char in
            switch char {
            case "A": // Address lines
                let line1 = Address.makeLine1(defaultValue: defaults.line1)
                let line2 = Address.makeLine2(defaultValue: defaults.line2)
                return partialResult + [line1, line2]
            case "C": // City
                let label = spec.cityNameType.localizedLabel
                let city = TextFieldElement(
                    configuration: Address.CityConfiguration(label: label, defaultValue: defaults.city)
                )
                city.isOptional = !spec.require.contains("C")
                return partialResult + [city]
            case "S": // State
                let label = spec.stateNameType.localizedLabel
                let state = TextFieldElement(
                    configuration: Address.StateConfiguration(label: label, defaultValue: defaults.state)
                )
                state.isOptional = !spec.require.contains("S")
                return partialResult + [state]
            case "Z": // Postal/Zip
                let label = spec.zipNameType.localizedLabel
                let regex = spec.zip
                let config = Address.PostalCodeConfiguration(regex: regex, label: label, defaultValue: defaults.postalCode)
                let postal = TextFieldElement(configuration: config)
                postal.isOptional = !spec.require.contains("Z")
                return partialResult + [postal]
            default:
                return partialResult
            }
        }
    }
}

