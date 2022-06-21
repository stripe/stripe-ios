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
 A section that contains a country dropdown and the country-specific address fields. It updates the address fields whenever the country changes to reflect the address format of that country.

 In addition to the physical address, it can collect other related fields like name.
 */
@_spi(STP) public class AddressSectionElement: SectionElement {
    /// Describes an address to use as a default for AddressSectionElement
    public struct Defaults {
        @_spi(STP) public static let empty = Defaults()
        var name: String?
        var phone: String?
        var company: String?

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
        public init(name: String? = nil, phone: String? = nil, company: String? = nil, city: String? = nil, country: String? = nil, line1: String? = nil, line2: String? = nil, postalCode: String? = nil, state: String? = nil) {
            self.name = name
            self.phone = phone
            self.company = company
            self.city = city
            self.country = country
            self.line1 = line1
            self.line2 = line2
            self.postalCode = postalCode
            self.state = state
        }
    }
    /// Describes which address fields to collect
    public enum CollectionMode {
        case all
        /// Collects country and postal code if the country is one of `countriesRequiringPostalCollection`
        /// - Note: Really only useful for cards, where we only collect postal for a handful of countries
        case countryAndPostal(countriesRequiringPostalCollection: [String])
    }
    /// Fields that this section can collect in addition to the address
    public struct AdditionalFields {
        public init(
            name: FieldConfiguration = .disabled,
            phone: FieldConfiguration = .disabled,
            company: FieldConfiguration = .disabled
        ) {
            self.name = name
            self.phone = phone
            self.company = company
        }
        
        public enum FieldConfiguration {
            case disabled
            case enabled(isOptional: Bool = false)
        }
        
        /// Configuration for a 'name' field
        public let name: FieldConfiguration
        
        /// Configuration for an 'phone' field
        public let phone: FieldConfiguration
        
        /// Configuration for a 'company' field
        public let company: FieldConfiguration
    }
    
    // MARK: - Elements
    public let name: TextFieldElement?
    public let phone: PhoneNumberElement?
    public let company: TextFieldElement?
    public let country: DropdownFieldElement
    public private(set) var line1: TextFieldElement?
    public private(set) var line2: TextFieldElement?
    public private(set) var city: TextFieldElement?
    public private(set) var state: TextFieldElement?
    public private(set) var postalCode: TextFieldElement?
    
    public let collectionMode: CollectionMode
    public var selectedCountryCode: String {
        return countryCodes[country.selectedIndex]
    }
    public var isValidAddress: Bool {
        return elements
            .compactMap { $0 as? TextFieldElement }
            .reduce(true) { isValid, element in
                if case .valid = element.validationState {
                    return isValid
                }
                return false
            }
    }
    let countryCodes: [String]

    public static func resolveCountryCodes(countries: [String]?, addressSpecProvider: AddressSpecProvider = .shared) -> [String] {
        return countries ?? addressSpecProvider.countries
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
        title: String? = nil,
        countries: [String]? = nil,
        locale: Locale = .current,
        addressSpecProvider: AddressSpecProvider = .shared,
        defaults: Defaults = .empty,
        collectionMode: CollectionMode = .all,
        additionalFields: AdditionalFields = .init()
    ) {
        let dropdownCountries = Self.resolveCountryCodes(countries: countries, addressSpecProvider: addressSpecProvider)
        self.collectionMode = collectionMode
        self.countryCodes = locale.sortedByTheirLocalizedNames(dropdownCountries)
        self.country = DropdownFieldElement.Address.makeCountry(
            label: String.Localized.country_or_region,
            countryCodes: countryCodes,
            defaultCountry: defaults.country,
            locale: locale
        )
        let initialCountry = countryCodes[country.selectedIndex]
        
        // Initialize additional fields
        self.name = {
            if case .enabled(let isOptional) = additionalFields.name {
                return TextFieldElement.NameConfiguration(defaultValue: defaults.name, isOptional: isOptional).makeElement()
            } else {
                return nil
            }
        }()
        self.phone = {
            if case .enabled(let isOptional) = additionalFields.phone {
                return PhoneNumberElement(
                    defaultValue: defaults.phone,
                    defaultCountry: initialCountry,
                    isOptional: isOptional
                )
            } else {
                return nil
            }
        }()
        self.company = {
            if case .enabled(let isOptional) = additionalFields.company {
                return TextFieldElement.CompanyConfiguration(isOptional: isOptional, defaultValue: defaults.company).makeElement()
            } else {
                return nil
            }
        }()
        
        super.init(
            title: title,
            elements: []
        )
        self.updateAddressFields(
            for: initialCountry,
            addressSpecProvider: addressSpecProvider,
            defaults: defaults
        )
        country.didUpdate = { [weak self] index in
            guard let self = self else { return }
            self.updateAddressFields(
                for: self.countryCodes[index],
                addressSpecProvider: addressSpecProvider
            )
        }
    }

    /// - Parameter defaults: Populates the new fields with the provided defaults, or the current fields' text if `nil`.
    private func updateAddressFields(
        for countryCode: String,
        addressSpecProvider: AddressSpecProvider,
        defaults: Defaults? = nil
    ) {
        // Create the new address fields' default text
        let defaults = defaults ?? Defaults(
            city: city?.text,
            country: nil,
            line1: line1?.text,
            line2: line2?.text,
            postalCode: postalCode?.text,
            state: state?.text
        )
        
        // Get the address spec for the country and filter out unused fields
        let spec = addressSpecProvider.addressSpec(for: countryCode)
        let fieldOrdering = spec.fieldOrdering.filter {
            switch collectionMode {
            case .all:
                return true
            case .countryAndPostal(let countriesRequiringPostalCollection):
                if case .postal = $0 {
                    return countriesRequiringPostalCollection.contains(countryCode)
                } else {
                   return false
                }
            }
        }
        // Re-create the address fields
        line1 = fieldOrdering.contains(.line) ?
            TextFieldElement.Address.makeLine1(defaultValue: defaults.line1) : nil
        line2 = fieldOrdering.contains(.line) ?
            TextFieldElement.Address.makeLine2(defaultValue: defaults.line2) : nil
        city = fieldOrdering.contains(.city) ?
            spec.makeCityElement(defaultValue: defaults.city) : nil
        state = fieldOrdering.contains(.state) ?
            spec.makeStateElement(defaultValue: defaults.state) : nil
        postalCode = fieldOrdering.contains(.postal) ?
            spec.makePostalElement(countryCode: countryCode, defaultValue: defaults.postalCode) : nil
        
        // Order the address fields according to `fieldOrdering`
        let addressFields: [TextFieldElement?] = fieldOrdering.reduce([]) { partialResult, fieldType in
            // This should be a flatMap but I'm having trouble satisfying the compiler
            switch fieldType {
            case .line:
                return partialResult + [line1, line2]
            case .city:
                return partialResult + [city]
            case .state:
                return partialResult + [state]
            case .postal:
                return partialResult + [postalCode]
            }
        }
        // Set the new address fields, including any additional fields
        elements = ([name, company] + [country] + addressFields + [phone]).compactMap { $0 }
    }
}
