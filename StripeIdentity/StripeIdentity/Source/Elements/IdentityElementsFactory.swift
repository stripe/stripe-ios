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
        "US": .init(type: .US_SSN_LAST4, label: String.Localized.last_4_of_ssn),
        "BR": .init(type: .BR_CPF, label: String.Localized.individual_cpf),
        "SG": .init(type: .SG_NRIC_OR_FIN, label: String.Localized.nric_or_fin),
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
                TextFieldElement(configuration: NameConfiguration(type: .given, defaultValue: nil), theme: IdentityUI.identityElementsUITheme),
                TextFieldElement(
                    configuration: NameConfiguration(type: .family, defaultValue: nil), theme: IdentityUI.identityElementsUITheme
                ),
            ],
            theme: IdentityUI.identityElementsUITheme
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
            elements: [
                TextFieldElement(configuration: TextFieldElement.IdentityDobConfiguration(), theme: IdentityUI.identityElementsUITheme)
            ],
            theme: IdentityUI.identityElementsUITheme
        )
    }

    // MARK: Address

    func makeAddressSection(countries: [String]) -> AddressSectionElement {
        return AddressSectionElement(
            title: String.Localized.address,
            countries: countries,
            locale: locale,
            addressSpecProvider: addressSpecProvider,
            theme: IdentityUI.identityElementsUITheme
        )
    }

    // MARK: Phone

    func makePhoneSection(countries: [String]) -> SectionElement {
        return SectionElement(
            title: String.Localized.phoneNumber,
            elements: [
                PhoneNumberElement(allowedCountryCodes: countries),
            ],
            theme: IdentityUI.identityElementsUITheme
        )
    }
}

extension IDNumberTextFieldConfiguration {
    init(
        spec: IdentityElementsFactory.IDNumberSpec?
    ) {
        self.init(
            type: spec?.type,
            label: spec?.label ?? String.Localized.personal_id_number,
            defaultValue: nil
        )
    }
}

extension TextFieldElement {
    // MARK: - Dob
    struct IdentityDobConfiguration: TextFieldElementConfiguration {
        private let dateFormatter: DateFormatter
        private let minDate: Date
        private let maxDate: Date = Date()

        init() {
            self.dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MMddyyyy"
            dateFormatter.locale = .current
            dateFormatter.timeZone = .current
            minDate = dateFormatter.date(from: "01011900")!
        }

        var label = "MM / DD / YYYY"

        var disallowedCharacters: CharacterSet = CharacterSet.stp_asciiDigit.inverted

        public func makeDisplayText(for text: String) -> NSAttributedString {
            var result: [Character] = []

            for (index, char) in text.enumerated() {
                if index < 2 {
                    result.append(char)
                } else if index == 2 {
                    result.append(" ")
                    result.append("/")
                    result.append(" ")
                    result.append(char)
                } else if index < 4 {
                    result.append(char)
                } else if index == 4 {
                    result.append(" ")
                    result.append("/")
                    result.append(" ")
                    result.append(char)
                } else {
                    result.append(char)
                }
            }

            return NSAttributedString(string: String(result))
        }

        func keyboardProperties(for text: String) -> TextFieldElement.KeyboardProperties {
            return .init(
                type: .asciiCapableNumberPad,
                textContentType: nil,
                autocapitalization: .none
            )
        }

        func maxLength(for text: String) -> Int {
            return 8
        }

        func validate(text: String, isOptional: Bool) -> TextFieldElement.ValidationState {
            // check date range
            guard let date = dateFormatter.date(from: text) else {
                return .invalid(TextFieldElement.Error.invalid(localizedDescription: String.Localized.date_of_birth_invalid))
            }

            if date > minDate && date < maxDate {
                return .valid
            } else {
                return .invalid(TextFieldElement.Error.invalid(localizedDescription: String.Localized.date_of_birth_invalid))
            }
        }

    }
}
