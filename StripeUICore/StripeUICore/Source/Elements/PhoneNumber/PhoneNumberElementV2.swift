//
//  PhoneNumberElementV2.swift
//  StripeUICore
//
//  Created by Yuki Tokuhiro on 6/21/22.
//

import UIKit
@_spi(STP) import StripeCore

/**
    A simple hstack of  [🇺🇸 + 1] `DropdownElement` and [ Phone number ] `TextFieldElement`
 */
@_spi(STP) public class PhoneNumberElementV2: ContainerElement {
    
    // MARK: - ContainerElement protocol
    public lazy var elements: [Element] = { [countryDropdownElement, textFieldElement] }()
    public var delegate: ElementDelegate?
    public lazy var view: UIView = {
        countryDropdownElement.view.directionalLayoutMargins.trailing = 0
        let hStackView = UIStackView(arrangedSubviews: [countryDropdownElement.view, textFieldElement.view])
        return hStackView
    }()
    
    // MARK: - sub-Elements
    let countryDropdownElement: DropdownFieldElement
    let textFieldElement: TextFieldElement
    
    // MARK: - Public properties
    public var phoneNumber: PhoneNumber? {
        return PhoneNumber(number: textFieldElement.text, countryCode: countryDropdownElement.selectedItem.rawData)
    }
    
    // MARK: - Initializer
    public init(
        allowedCountryCodes: [String],
        defaultCountryCode: String,
        defaultPhoneNumber: String? = nil,
        isOptional: Bool = false
    ) {
        let countryDropdownElement = DropdownFieldElement.makeCountryCode(countryCodes: allowedCountryCodes, defaultCountry: defaultCountryCode)
        self.countryDropdownElement = countryDropdownElement
        self.textFieldElement = TextFieldElement.PhoneNumberConfigurationV2(
            defaultValue: defaultPhoneNumber,
            isOptional: isOptional,
            countryCodeProvider: {
                return countryDropdownElement.selectedItem.rawData
            }
        ).makeElement()
        self.countryDropdownElement.delegate = self
        self.textFieldElement.delegate = self
    }
}

// MARK: - DropdownFieldElement helper
extension DropdownFieldElement {
    static func makeCountryCode(
        countryCodes: [String],
        defaultCountry: String? = nil,
        locale: Locale = Locale.current
    ) -> DropdownFieldElement {
        let countryCodes = locale.sortedByTheirLocalizedNames(countryCodes)
        let countryDisplayStrings: [DropdownFieldElement.DropdownItem] = countryCodes.map {
            let flagEmoji = String.countryFlagEmoji(for: $0) ?? ""              // 🇺🇸
            let name = locale.localizedString(forRegionCode: $0) ?? $0          // United States
            let prefix = PhoneNumber.Metadata.metadata(for: $0)?.prefix ?? ""   // +1
            return .init(
                pickerDisplayName: "\(flagEmoji) \(name) \(prefix)",            // 🇺🇸 United States +1
                labelDisplayName: "\(flagEmoji) \(prefix)",
                accessibilityLabel: "\(name) \(prefix)",
                rawData: $0
            )
        }
        let defaultCountry = defaultCountry ?? locale.regionCode ?? ""
        let defaultCountryIndex = countryCodes.firstIndex(of: defaultCountry) ?? 0
        return DropdownFieldElement(
            items: countryDisplayStrings,
            defaultIndex: defaultCountryIndex,
            label: nil
        )
    }
}
