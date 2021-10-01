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

    let locale: Locale

    init(locale: Locale = .current) {
        self.locale = locale
    }

    /**
     Creates a section with a country dropdown and ID number input.
     - Parameters:
       - acceptedCountryCodes: List of countries we accept ID numbers from.
     */
    func makeIDNumberSection(acceptedCountryCodes: [String]) -> SectionElement? {
        guard !acceptedCountryCodes.isEmpty else {
            return nil
        }

        // TODO(mludowise|IDPROD-2543): We'll need to tweak this to better
        // handle unsupported countries.

        let sortedCountryCodes = locale.sortedByTheirLocalizedNames(
            acceptedCountryCodes,
            thisRegionFirst: true
        )

        let country = DropdownFieldElement.Address.makeCountry(
            label: String.Localized.country,
            countryCodes: sortedCountryCodes,
            locale: locale
        )

        // TODO(mludowise|IDPROD-2455): Add ID text field input

        let section = SectionElement(
            title: String.Localized.id_number_title,
            elements: [country]
        )

        return section
    }
}
