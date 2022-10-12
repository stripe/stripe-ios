//
//  PhoneNumberElement.swift
//  StripeUICore
//
//  Created by Yuki Tokuhiro on 6/21/22.
//

import UIKit
@_spi(STP) import StripeCore

/**
    A simple hstack of  [🇺🇸 + 1] `DropdownElement` and [ Phone number ] `TextFieldElement`
 */
@_spi(STP) public class PhoneNumberElement: ContainerElement {
    
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
    
    public var hasBeenModified: Bool {
        return defaultPhoneNumber?.number != phoneNumber?.number ||
        defaultPhoneNumber?.countryCode != phoneNumber?.countryCode
    }
    
    // MARK: - Private properties
    private var defaultPhoneNumber: PhoneNumber?
    
    // MARK: - Initializer
    /**
     Creates an address section with a country dropdown populated from the given list of countryCodes.

     - Parameters:
       - allowedCountryCodes: List of region codes to display in the country picker dropdown. If nil, defaults to ~all countries.
       - defaultCountryCode: The country code that's initially selected in the dropdown. **This is ignored** if `defaultPhoneNumber` is in E.164 format in favor of the phone number's country code.
       - defaultPhoneNumber:The initial value of the phone number text field. Note: If provided in E.164 format, the country prefix is removed.
       - locale: Locale used to generate the display names for each country and as the default country if none is provided.
       - theme: Theme used to stylize the phone number element
     
     - Note: The default parameters are not used as-is - we do extra logic!
     */
    public init(
        allowedCountryCodes: [String]? = nil,
        defaultCountryCode: String? = nil,
        defaultPhoneNumber: String? = nil,
        isOptional: Bool = false,
        locale: Locale = .current,
        theme: ElementsUITheme = .default
    ) {
        let defaults = Self.deriveDefaults(countryCode: defaultCountryCode, phoneNumber: defaultPhoneNumber)
        let allowedCountryCodes = allowedCountryCodes ?? PhoneNumber.Metadata.allMetadata.map { $0.regionCode }
        let countryDropdownElement = DropdownFieldElement.makeCountryCode(
            countryCodes: allowedCountryCodes,
            defaultCountry: defaults.countryCode,
            locale: locale,
            theme: theme
        )
        self.countryDropdownElement = countryDropdownElement
        self.textFieldElement = TextFieldElement.PhoneNumberConfiguration(
            defaultValue: defaults.phoneNumber,
            isOptional: isOptional,
            countryCodeProvider: {
                return countryDropdownElement.selectedItem.rawData
            }
        ).makeElement(theme: theme)
        self.defaultPhoneNumber = phoneNumber
        self.countryDropdownElement.delegate = self
        self.textFieldElement.delegate = self
    }
    
    // MARK: - Element protocol
    public func beginEditing() -> Bool {
        return textFieldElement.beginEditing()
    }
    
    // MARK: - ElementDelegate
    public func didUpdate(element: Element) {
        if element === textFieldElement && textFieldElement.didReceiveAutofill {
            // Autofilled numbers may already include the country code, so check if that's the case.
            // Note: We only validate against the currently selected country code, as an autofilled number _without_ a country code can trigger false positives, e.g. "2481234567" could be either "(248) 123-4567" (a phone number from Michigan, USA with no country code) or "+248 1 234 567" (a phone number from Seychelles with a country code). We can assume that generally, a user's autofilled phone number will match their phone's region setting.
            // Autofilled numbers can include the + prefix indicating a country code, but we can't tell if they do here, as by the time we get here the input has already been sanitized and the "+" has been removed.
            let countryCode = countryDropdownElement.selectedItem.rawData
            if let prefix = PhoneNumber.Metadata.metadata(for: countryCode)?.prefix.dropFirst(), textFieldElement.text.hasPrefix(prefix) {
                let unprefixedNumber = String(textFieldElement.text.dropFirst(prefix.count))
                // Double check that we actually have a valid phone number without the prefix.
                if let phoneNumber = PhoneNumber(number: unprefixedNumber, countryCode: countryCode), phoneNumber.isComplete {
                    textFieldElement.setText(unprefixedNumber)
                    textFieldElement.endEditing()
                    // Setting the text directly triggers another update cycle, so short-circuit here to avoid double updating.
                    return
                }
            }
        }
        delegate?.didUpdate(element: self)
    }
    
    // MARK: - Helpers
    static func deriveDefaults(countryCode: String?, phoneNumber: String?) -> (countryCode: String?, phoneNumber: String?) {
        // If the phone number is E164, derive defaults from that
        if let phoneNumber = phoneNumber, let e164PhoneNumber = PhoneNumber.fromE164(phoneNumber) {
            return (e164PhoneNumber.countryCode, e164PhoneNumber.number)
        } else {
            return (countryCode, phoneNumber)
        }
    }
    
    func selectCountry(index: Int, shouldUpdateDefaultNumber: Bool = false) {
        countryDropdownElement.select(index: index)
        
        if shouldUpdateDefaultNumber {
            self.defaultPhoneNumber = phoneNumber
        }
    }
}

// MARK: - DropdownFieldElement helper
extension DropdownFieldElement {
    static func makeCountryCode(
        countryCodes: [String],
        defaultCountry: String? = nil,
        locale: Locale,
        theme: ElementsUITheme
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
            label: nil,
            theme: theme
        )
    }
}
