//
//  IndividualElementsFactory.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 9/23/21.
//

import Foundation
@_spi(STP) import StripeUICore
@_spi(STP) import StripeCore

/**
 Factory to create form elements needed for the 'Individual' screen of the
 Identity flow where the user is asked to enter additional personal information.
 */
struct IdentityElementsFactory {

    struct IDNumberSpec {
        let type: IDNumberTextFieldConfiguration.IDNumberType?
        let label: String
    }

    let locale: Locale

    init(locale: Locale = .current) {
        self.locale = locale
    }

    /**
     Creates a section with a country dropdown and ID number input.
     - Parameters:
       - countryToIDNumberTypes: Map of accepted country codes which we can accept ID numbers from to the ID type.
     */
    func makeIDNumberSection(countryToIDNumberTypes: [String: IDNumberSpec]) -> SectionElement? {
        guard !countryToIDNumberTypes.isEmpty else {
            return nil
        }

        // TODO(mludowise|IDPROD-2543): We'll need to tweak this to better
        // handle unsupported countries.

        let sortedCountryCodes = locale.sortedByTheirLocalizedNames(
            Array(countryToIDNumberTypes.keys),
            thisRegionFirst: true
        )

        let country = DropdownFieldElement.Address.makeCountry(
            label: String.Localized.country,
            countryCodes: sortedCountryCodes,
            locale: locale
        )

        let defaultCountrySpec = countryToIDNumberTypes[sortedCountryCodes[country.defaultIndex]]
        let id = TextFieldElement(configuration: IDNumberTextFieldConfiguration(spec: defaultCountrySpec))
        let section = SectionElement(
            title: String.Localized.id_number_title,
            elements: [country, id]
        )

        // Change ID input based on country selection
        country.didUpdate = { index in
            let selectedCountryCode = sortedCountryCodes[index]
            let id = TextFieldElement(configuration: IDNumberTextFieldConfiguration(spec: countryToIDNumberTypes[selectedCountryCode]))
            section.elements = [country, id]
        }

        return section
    }
}

extension IDNumberTextFieldConfiguration {
    init(spec: IdentityElementsFactory.IDNumberSpec?) {
        self.init(
            type: spec?.type,
            label: spec?.label ?? String.Localized.personal_id_number
        )
    }
}
