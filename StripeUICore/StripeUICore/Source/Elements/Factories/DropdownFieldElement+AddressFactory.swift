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
            theme: ElementsUITheme = .default,
            defaultCountry: String? = nil,
            locale: Locale = Locale.current
        ) -> DropdownFieldElement {
            let dropdownItems: [DropdownItem] = countryCodes.map {
                let countryName = locale.localizedString(forRegionCode: $0) ?? $0
                return DropdownItem(pickerDisplayName: countryName, labelDisplayName: countryName, accessibilityLabel: countryName, rawData: $0)
            }
            let defaultCountry = defaultCountry ?? locale.regionCode ?? ""
            let defaultCountryIndex = countryCodes.firstIndex(of: defaultCountry) ?? 0
            
            return DropdownFieldElement(
                items: dropdownItems,
                defaultIndex: defaultCountryIndex,
                label: String.Localized.country_or_region,
                theme: theme
            )
        }
    }
}
