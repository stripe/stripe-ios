//
//  IdNumberElement.swift
//  StripeIdentity
//
//  Created by Chen Cen on 2/2/23.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
import UIKit

/// Section that collects Id number of different countries.
class IdNumberElement: ContainerElement {
    var elements: [StripeUICore.Element]

    weak var delegate: StripeUICore.ElementDelegate?

    var view: UIView

    let countryCodes: [String]
    let country: DropdownFieldElement
    var id: TextFieldElement

    init(countryToIDNumberTypes: [String: IdentityElementsFactory.IDNumberSpec], locale: Locale) {

        countryCodes = locale.sortedByTheirLocalizedNames(
            Array(countryToIDNumberTypes.keys),
            thisRegionFirst: true
        )

        country = DropdownFieldElement.Address.makeCountry(
            label: String.Localized.country,
            countryCodes: countryCodes,
            locale: locale,
            disableDropdownWithSingleCountry: true
        )

        let defaultCountrySpec = countryToIDNumberTypes[countryCodes[country.selectedIndex]]
        id = TextFieldElement(
            configuration: IDNumberTextFieldConfiguration(spec: defaultCountrySpec)
        )

        let section = SectionElement(
            title: String.Localized.id_number_title,
            elements: [country, id]
        )

        view = section.view

        elements = [section]

        // Change ID input based on country selection
        country.didUpdate = { index in
            let selectedCountryCode = self.countryCodes[index]
            self.id = TextFieldElement(
                configuration: IDNumberTextFieldConfiguration(
                    spec: countryToIDNumberTypes[selectedCountryCode]
                )
            )
            section.elements = [self.country, self.id]
        }

        section.delegate = self
    }

    func collectedIdNumber() -> StripeAPI.VerificationPageDataIdNumber {
        let selectedCountryCode = countryCodes[country.selectedIndex]
        if selectedCountryCode == "US" {
            return StripeAPI.VerificationPageDataIdNumber(
                country: countryCodes[country.selectedIndex],
                partialValue: id.text,
                value: nil
            )
        } else {
            return StripeAPI.VerificationPageDataIdNumber(
                country: countryCodes[country.selectedIndex],
                partialValue: nil,
                value: id.text
            )
        }

    }
}

// MARK: - ElementDelegate
extension IdNumberElement: ElementDelegate {
    func didUpdate(element: Element) {
        delegate?.didUpdate(element: element)
    }

    func continueToNextField(element: Element) {
        delegate?.continueToNextField(element: element)
    }
}
