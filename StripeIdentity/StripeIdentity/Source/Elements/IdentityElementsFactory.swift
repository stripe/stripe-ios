//
//  IdentityElementsFactory.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 9/23/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore

/// Factory to create form elements needed for the 'Individual' screen of the
/// Identity flow where the user is asked to enter additional personal information.
struct IdentityElementsFactory {

    struct IDNumberSpec {
        let type: IDNumberTextFieldConfiguration.IDNumberType?
        let label: String
    }

    let locale: Locale
    let addressSpecProvider: AddressSpecProvider

    let dateFormatter: DateFormatter

    static let supportedCountryToIDNumberTypes: [String: IdentityElementsFactory.IDNumberSpec] = [
        "US": .init(type: .US_SSN_LAST4, label: "Last 4 of Social Security number"),
        "BR": .init(type: .BR_CPF, label: "Individual CPF"),
        "SG": .init(type: .SG_NRIC_OR_FIN, label: "NRIC or FIN"),
    ]

    init(
        locale: Locale = .current,
        addressSpecProvider: AddressSpecProvider = .shared
    ) {
        self.locale = locale
        self.addressSpecProvider = addressSpecProvider

        self.dateFormatter = DateFormatter()
        self.dateFormatter.dateFormat = "MM / dd / yyyy"
    }

    // MARK: Name

    func makeNameSection() -> SectionElement {
        typealias NameConfiguration = TextFieldElement.NameConfiguration

        return SectionElement(
            title: String.Localized.name,
            elements: [
                TextFieldElement(configuration: NameConfiguration(type: .given, defaultValue: nil)),
                TextFieldElement(
                    configuration: NameConfiguration(type: .family, defaultValue: nil)
                ),
            ]
        )
    }

    // MARK: ID Number

    /// Creates a section with a country dropdown and ID number input.
    /// - Parameters:
    ///   - idNumberCountires: Array of accepted country codes which we can accept ID numbers from to the ID type.
    func makeIDNumberSection(idNumberCountries: [String]) -> IdNumberElement? {
        let countryToIDNumberTypes = IdentityElementsFactory.supportedCountryToIDNumberTypes.filter(
            { idNumberCountries.contains($0.key) }
        )
        guard !countryToIDNumberTypes.isEmpty else {
            return nil
        }

        return IdNumberElement(countryToIDNumberTypes: countryToIDNumberTypes, locale: locale)
    }

    // MARK: DOB

    func makeDateOfBirthSection() -> SectionElement {
        return  SectionElement(
            title: String.Localized.date_of_birth,
            elements: [DateFieldElement(
                label: "MM / DD / YYYY",
                minimumDate: dateFormatter.date(from: "01 / 01 / 1990"),
                maximumDate: Date(),
                locale: locale,
                customDateFormatter: dateFormatter
                ),
            ]
        )
    }

    // MARK: Address

    func makeAddressSection(countries: [String]) -> AddressSectionElement {
        return AddressSectionElement(
            title: String.Localized.address,
            countries: countries,
            locale: locale,
            addressSpecProvider: addressSpecProvider
        )
    }
}

extension IDNumberTextFieldConfiguration {
    init(
        spec: IdentityElementsFactory.IDNumberSpec?
    ) {
        self.init(
            type: spec?.type,
            label: spec?.label ?? String.Localized.personal_id_number
        )
    }
}
