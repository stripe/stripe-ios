//
//  AddressSectionElement.swift
//  StripeUICore
//
//  Created by Mel Ludowise on 10/5/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeCore

/**
 A section that contains a country dropdown and the country-specific address fields
 */
@_spi(STP) public class AddressSectionElement: SectionElement {
    /// Describes an address to use as a default for AddressSectionElement
    public struct Defaults {
        @_spi(STP) public static let empty = Defaults()

        /// City, district, suburb, town, or village.
        var city: String?

        /// Two-letter country code (ISO 3166-1 alpha-2).
        var country: String?

        /// Address line 1 (e.g., street, PO Box, or company name).
        var line1: String?

        /// Address line 2 (e.g., apartment, suite, unit, or building).
        var line2: String?

        /// ZIP or postal code.
        var postalCode: String?

        /// State, county, province, or region.
        var state: String?

        /// Initializes an Address
        public init(city: String? = nil, country: String? = nil, line1: String? = nil, line2: String? = nil, postalCode: String? = nil, state: String? = nil) {
            self.city = city
            self.country = country
            self.line1 = line1
            self.line2 = line2
            self.postalCode = postalCode
            self.state = state
        }
    }

    public let country: DropdownFieldElement
    public private(set) var line1: TextFieldElement?
    public private(set) var line2: TextFieldElement?
    public private(set) var city: TextFieldElement?
    public private(set) var state: TextFieldElement?
    public private(set) var postalCode: TextFieldElement?

    let countryCodes: [String]

    public var selectedCountryCode: String? {
        return countryCodes.stp_boundSafeObject(at: country.selectedIndex)
    }

    /**
     Creates an address section with a country dropdown populated from the given list of countryCodes.

     - Parameters:
       - title: The title for this section
       - countries: List of region codes to display in the country picker dropdown. If nil, the list of countries from `addressSpecProvider` is used instead.
       - locale: Locale used to generate the display names for each country
       - addressSpecProvider: Determines the list of address fields to display for a selected country
       - defaults: Default address to prepopulate address fields with
     */
    public init(
        title: String,
        countries: [String]? = nil,
        locale: Locale = .current,
        addressSpecProvider optionalAddressSpecProvider: AddressSpecProvider? = nil,
        defaults optionalDefaults: Defaults? = nil
    ) {
        // TODO: After switching to Xcode 12.5 (which fixed @_spi default initailizers)
        // we can make these into default initializers instead of optionals.
        let addressSpecProvider: AddressSpecProvider = optionalAddressSpecProvider ?? .shared
        let defaults: Defaults = optionalDefaults ?? .empty

        let dropdownCountries: [String]
        if let countries = countries {
            assert(!countries.isEmpty, "`countries` must contain at least one country")
            dropdownCountries = countries
        } else {
            assert(!addressSpecProvider.countries.isEmpty, "`addressSpecProvider` must contain at least one country")
            dropdownCountries = addressSpecProvider.countries
        }

        self.countryCodes = locale.sortedByTheirLocalizedNames(dropdownCountries)

        country = DropdownFieldElement.Address.makeCountry(
            label: String.Localized.country_or_region,
            countryCodes: countryCodes,
            defaultCountry: defaults.country,
            locale: locale
        )
        super.init(
            title: title,
            elements: []
        )
        self.updateAddressFields(
            for: countryCodes[country.selectedIndex],
            addressSpecProvider: addressSpecProvider,
            defaults: defaults
        )
        country.didUpdate = { [weak self] index in
            guard let self = self else { return }
            self.updateAddressFields(
                for: self.countryCodes[index],
                addressSpecProvider: addressSpecProvider,
                defaults: defaults
            )
        }

    }

    private func updateAddressFields(
        for countryCode: String,
        addressSpecProvider: AddressSpecProvider,
        defaults: Defaults
    ) {
        // Populate the address fields based on the given country and spec
        let spec = addressSpecProvider.addressSpec(for: countryCode)
        let format = spec.format
        let fields: [TextFieldElement?] = format.reduce([]) { partialResult, char in
            switch char {
            case "A": // Address lines
                line1 = AddressSectionElement.makeLine1(defaultValue: line1?.text ?? defaults.line1)
                line2 = AddressSectionElement.makeLine2(defaultValue: line2?.text ?? defaults.line2)
                return partialResult + [line1, line2]
            case "C": // City
                let label = spec.cityNameType.localizedLabel
                city = TextFieldElement(
                    configuration: Address.CityConfiguration(label: label, defaultValue: city?.text ?? defaults.city)
                )
                city?.isOptional = !spec.require.contains("C")
                return partialResult + [city]
            case "S": // State
                let label = spec.stateNameType.localizedLabel
                state = TextFieldElement(
                    configuration: Address.StateConfiguration(label: label, defaultValue: state?.text ?? defaults.state)
                )
                state?.isOptional = !spec.require.contains("S")
               return partialResult + [state]
            case "Z": // Postal/Zip
                let label = spec.zipNameType.localizedLabel
                let regex = spec.zip
                let config = Address.PostalCodeConfiguration(regex: regex, label: label, defaultValue: postalCode?.text ?? defaults.postalCode)
                postalCode = TextFieldElement(
                    configuration: config
                )
                postalCode?.isOptional = !spec.require.contains("Z")
                return partialResult + [postalCode]
            default:
                return partialResult
            }
        }
        self.elements = [self.country] + fields.compactMap { $0 }
        removeUnapplicableFields()
    }

    private func removeUnapplicableFields() {
        // If there are fields that no longer apply because the spec was updated,
        // set them to nil
        if !elements.contains(where: { $0 === line1}) {
            line1 = nil
            line2 = nil
        }
        if !elements.contains(where: { $0 === city}) {
            city = nil
        }
        if !elements.contains(where: { $0 === state}) {
            state = nil
        }
        if !elements.contains(where: { $0 === postalCode}) {
            postalCode = nil
        }
    }
}

private extension AddressSectionElement {
    typealias Address = TextFieldElement.Address

    static func makeLine1(defaultValue: String?) -> TextFieldElement {
        return TextFieldElement(
            configuration: Address.LineConfiguration(lineType: .line1, defaultValue: defaultValue)
        )
    }

    static func makeLine2(defaultValue: String?) -> TextFieldElement {
        let line2 = TextFieldElement(
            configuration: Address.LineConfiguration(lineType: .line2, defaultValue: defaultValue)
        )
        line2.isOptional = true // Hardcode all line2 as optional
        return line2
    }
}
