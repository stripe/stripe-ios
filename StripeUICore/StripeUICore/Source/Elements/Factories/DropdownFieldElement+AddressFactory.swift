//
//  DropdownFieldElement+AddressFactory.swift
//  StripeUICore
//
//  Created by Mel Ludowise on 9/28/21.
//

import Foundation
@_spi(STP) import StripeCore

@_spi(STP) public extension DropdownFieldElement {
    // MARK: - Address

    enum Address {

        // MARK: - Country

        public static func makeCountry(
            label: String,
            countryCodes: [String],
            defaultCountry: String? = nil,
            locale: Locale = Locale.current
        ) -> DropdownFieldElement {
            let countryDisplayStrings = countryCodes.map {
                locale.localizedString(forRegionCode: $0) ?? $0
            }
            let defaultCountry = defaultCountry ?? locale.regionCode ?? ""
            let defaultCountryIndex = countryCodes.firstIndex(of: defaultCountry) ?? 0
            return DropdownFieldElement(
                items: countryDisplayStrings,
                defaultIndex: defaultCountryIndex,
                label: String.Localized.country_or_region
            )
        }
    }
}
