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
        addressSpecProvider: AddressSpecProvider = .shared
    ) -> SectionElement {
        let countryCodes = locale.sortedByTheirLocalizedNames(addressSpecProvider.countries)
        let country = DropdownFieldElement(
            label: String.Localized.country_or_region,
            countryCodes: countryCodes
        ) { params, index in
            let billing = params.paymentMethodParams.billingDetails ?? STPPaymentMethodBillingDetails()
            let address = billing.address ?? STPPaymentMethodAddress()
            address.country = countryCodes[index]
            params.paymentMethodParams.billingDetails = billing
            return params
        }
        let section = SectionElement(
            title: String.Localized.billing_address,
            elements: [country] + addressFields(for: countryCodes[country.selectedIndex])
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
        addressSpecProvider: AddressSpecProvider = .shared
    ) -> [TextFieldElement] {
        let spec = addressSpecProvider.addressSpec(for: country)
        let format = spec.format
        return format.reduce([]) { partialResult, char in
            switch char {
            case "A": // Address lines
                // Always render two address lines, making the second line optional.
                let line1 = TextFieldElement(configuration: Address.LineConfiguration(lineType: .line1))
                let line2 = TextFieldElement(configuration: Address.LineConfiguration(lineType: .line2))
                line2.isOptional = true
                return partialResult + [line1, line2]
            case "C": // City
                let label = spec.cityNameType.localizedLabel
                let city = TextFieldElement(configuration: Address.CityConfiguration(label: label))
                city.isOptional = !spec.require.contains("C")
                return partialResult + [city]
            case "S": // State
                let label = spec.stateNameType.localizedLabel
                let state = TextFieldElement(configuration: Address.StateConfiguration(label: label))
                state.isOptional = !spec.require.contains("S")
                return partialResult + [state]
            case "Z": // Postal/Zip
                let label = spec.zipNameType.localizedLabel
                let regex = spec.zip
                let config = Address.PostalCodeConfiguration(regex: regex, label: label)
                let postal = TextFieldElement(configuration: config)
                postal.isOptional = !spec.require.contains("Z")
                return partialResult + [postal]
            default:
                return partialResult
            }
        }
    }
}

