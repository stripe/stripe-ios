//
//  AddressSectionElement.swift
//  StripeUICore
//
//  Created by Mel Ludowise on 10/5/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeCore
import UIKit

/**
 A section that contains a country dropdown and the country-specific address fields. It updates the address fields whenever the country changes to reflect the address format of that country.

 In addition to the physical address, it can collect other related fields like name.
 */
@_spi(STP) public class AddressSectionElement: ContainerElement {
    public typealias DidUpdateAddress = (AddressDetails) -> Void

    /// Describes an address to use as a default for AddressSectionElement
    public struct AddressDetails: Equatable {
        @_spi(STP) public static let empty = AddressDetails()
        public var name: String?
        public var phone: String?
        public var email: String?
        public var address: Address

        /// Initializes an Address
        public init(name: String? = nil, phone: String? = nil, email: String? = nil, address: Address = .init()) {
            self.name = name
            self.phone = phone
            self.email = email
            self.address = address
        }

        public struct Address: Equatable {
            /// City, district, suburb, town, or village.
            public var city: String?

            /// Two-letter country code (ISO 3166-1 alpha-2).
            public var country: String?

            /// Address line 1 (e.g., street, PO Box, or company name).
            public var line1: String?

            /// Address line 2 (e.g., apartment, suite, unit, or building).
            public var line2: String?

            /// ZIP or postal code.
            public var postalCode: String?

            /// State, county, province, or region.
            public var state: String?

            /// Initializes an Address
            public init(city: String? = nil, country: String? = nil, line1: String? = nil, line2: String? = nil, postalCode: String? = nil, state: String? = nil) {
                self.city = city
                self.country = country
                self.line1 = line1
                self.line2 = line2
                self.postalCode = postalCode
                self.state = state
            }
        }
    }

    /// Describes which address fields to collect.
    public enum FieldsToCollect: Equatable {
        /// Only collects the country. Used by Payment Methods that require a country but not the rest of the address.
        case country
        /// Collects country and postal code.
        case countryAndPostal
        /// Collects all address fields.
        case all
    }

    /// Describes how autocomplete is presented when collecting all address fields.
    /// This has no effect when the resolved fields to collect are not ``FieldsToCollect/all``.
    public enum AutocompleteStyle: Equatable {
        /// Does not show autocomplete.
        case none
        /// Shows country and the autocomplete line entry point.
        /// - Parameter supportedCountries: Countries that support autocomplete. If nil, all countries are supported.
        ///   Callers should expand when an unsupported country is selected.
        case compact(supportedCountries: [String]? = nil)
        /// Shows the full address form. Line 1 opens autocomplete when the selected country is supported.
        /// - Parameter supportedCountries: Countries that support autocomplete. If nil, all countries are supported.
        ///   Unsupported countries use manual entry.
        case expanded(supportedCountries: [String]? = nil)
    }
    /// Fields that this section can collect in addition to the address
    public struct AdditionalFields {
        public init(
            name: FieldConfiguration = .disabled,
            phone: FieldConfiguration = .disabled,
            email: FieldConfiguration = .disabled,
            billingSameAsShippingCheckbox: FieldConfiguration = .disabled
        ) {
            self.name = name
            self.phone = phone
            self.email = email
            self.billingSameAsShippingCheckbox = billingSameAsShippingCheckbox
        }

        public enum FieldConfiguration {
            case disabled
            case enabled(isOptional: Bool = false)
        }

        public let name: FieldConfiguration
        public let phone: FieldConfiguration
        public let email: FieldConfiguration
        public let billingSameAsShippingCheckbox: FieldConfiguration
    }

    // MARK: Element protocol
    public let elements: [Element]
    public weak var delegate: ElementDelegate?
    public lazy var view: UIView = {
        let vStack = UIStackView(arrangedSubviews: [addressSection.view, sameAsCheckbox.view].compactMap { $0 })
        vStack.axis = .vertical
        vStack.spacing = 16
        return vStack
    }()

    // MARK: Elements
    let addressSection: SectionElement
    public let name: TextFieldElement?
    public let phone: PhoneNumberElement?
    public let email: TextFieldElement?
    public let country: DropdownFieldElement
    public private(set) var autoCompleteLine: DummyAddressLine?
    public private(set) var line1: TextFieldElement?
    public private(set) var line2: TextFieldElement?
    public private(set) var city: TextFieldElement?
    public private(set) var state: TextOrDropdownElement?
    public private(set) var postalCode: TextFieldElement?
    public let sameAsCheckbox: CheckboxElement

    // MARK: Other properties
    public var defaultFieldsToCollect: FieldsToCollect {
        didSet {
            if oldValue != defaultFieldsToCollect {
                updateAddressFields(for: countryCodes[country.selectedIndex], address: nil)
            }
        }
    }
    private let minimumFieldsToCollectByCountry: [String: FieldsToCollect]
    public var autocompleteStyle: AutocompleteStyle {
        didSet {
            if oldValue != autocompleteStyle {
                updateAddressFields(for: countryCodes[country.selectedIndex], address: nil)
            }
        }
    }
    public var selectedCountryCode: String {
        get {
            return countryCodes[country.selectedIndex]
        }
        set {
            guard let index = countryCodes.firstIndex(of: newValue) else { return }
            selectCountry(index: index)
        }
    }
    public var addressDetails: AddressDetails {
        let address = AddressDetails.Address(city: city?.text, country: selectedCountryCode, line1: line1?.text, line2: line2?.text, postalCode: postalCode?.text, state: state?.rawData)
        return .init(name: name?.text, phone: phone?.phoneNumber?.string(as: .e164), email: email?.text, address: address)
    }

    public let countryCodes: [String]
    let addressSpecProvider: AddressSpecProvider
    let theme: ElementsAppearance
    private(set) var defaults: AddressDetails
    @_spi(STP) public var didTapAutocompleteButton: () -> Void
    public var didUpdate: DidUpdateAddress?

    // MARK: - Implementation
    /**
     Creates an address section with a country dropdown populated from the given list of countryCodes.

     - Parameters:
       - title: The title for this section
       - countries: List of region codes to display in the country picker dropdown. If nil, the list of countries from `addressSpecProvider` is used instead.
       - locale: Locale used to generate the display names for each country
       - addressSpecProvider: Determines the list of address fields to display for a selected country
       - defaults: Default address to prepopulate address fields with
       - defaultFieldsToCollect: The address fields to collect when the selected country has no greater minimum requirement
       - minimumFieldsToCollectByCountry: Per-country minimum address fields. These requirements never reduce `defaultFieldsToCollect`.
       - autocompleteStyle: How to present autocomplete when collecting all address fields
     */
    public init(
        title: String? = nil,
        countries: [String]? = nil,
        locale: Locale = .current,
        addressSpecProvider: AddressSpecProvider = .shared,
        defaults: AddressDetails = .empty,
        defaultFieldsToCollect: FieldsToCollect = .all,
        minimumFieldsToCollectByCountry: [String: FieldsToCollect] = [:],
        autocompleteStyle: AutocompleteStyle = .none,
        additionalFields: AdditionalFields = .init(),
        theme: ElementsAppearance = .default,
        presentAutoComplete: @escaping () -> Void = { }
    ) {
        let dropdownCountries = countries?.map { $0.uppercased() } ?? addressSpecProvider.countries
        let countryCodes = locale.sortedByTheirLocalizedNames(dropdownCountries)
        self.defaultFieldsToCollect = defaultFieldsToCollect
        self.minimumFieldsToCollectByCountry = minimumFieldsToCollectByCountry
        self.autocompleteStyle = autocompleteStyle
        self.countryCodes = countryCodes
        self.country = DropdownFieldElement.Address.makeCountry(
            label: String.Localized.country_or_region,
            countryCodes: countryCodes,
            theme: theme,
            defaultCountry: defaults.address.country,
            locale: locale
        )
        self.defaults = defaults
        self.addressSpecProvider = addressSpecProvider
        self.theme = theme
        self.didTapAutocompleteButton = presentAutoComplete

        let initialCountry = countryCodes[country.selectedIndex]

        // Initialize additional fields
        self.name = {
            if case .enabled(let isOptional) = additionalFields.name {
                return TextFieldElement.NameConfiguration(defaultValue: defaults.name,
                                                          isOptional: isOptional).makeElement(theme: theme)
            } else {
                return nil
            }
        }()
        self.phone = {
            if case .enabled(let isOptional) = additionalFields.phone {
                return PhoneNumberElement(
                    allowedCountryCodes: countryCodes,
                    defaultCountryCode: initialCountry,
                    defaultPhoneNumber: defaults.phone,
                    isOptional: isOptional,
                    locale: locale,
                    theme: theme
                )
            } else {
                return nil
            }
        }()
        self.email = {
            if case .enabled(let isOptional) = additionalFields.email {
                return TextFieldElement.makeEmail(defaultValue: defaults.email, isOptional: isOptional, theme: theme)
            } else {
                return nil
            }
        }()
        self.sameAsCheckbox = CheckboxElement(theme: theme, label: String.Localized.billing_same_as_shipping, isSelectedByDefault: true)
        if case .enabled = additionalFields.billingSameAsShippingCheckbox, let defaultCountry = defaults.address.country, countryCodes.contains(defaultCountry) {
            // Country must exist in the dropdown, otherwise this address can't be same as shipping
            sameAsCheckbox.view.isHidden = false
        } else {
            sameAsCheckbox.view.isHidden = true
        }
        addressSection = SectionElement(title: title, elements: [], theme: theme)
        elements = ([addressSection, sameAsCheckbox] as [Element?]).compactMap { $0 }
        elements.forEach { $0.delegate = self }

        self.updateAddressFields(
            for: initialCountry,
            address: defaults.address
        )
        country.didUpdate = { [weak self] index in
            guard let self else { return }
            self.selectCountry(index: index)
        }
        sameAsCheckbox.didToggle = { [weak self] isToggled in
            guard let self else { return }
            if isToggled {
                let index = self.country.items.firstIndex {
                    $0.rawData == self.defaults.address.country ?? ""
                } ?? self.country.selectedIndex
                // Return to the default country and populate its address.
                self.selectCountry(index: index, address: self.defaults.address)
            } else {
                // Clear the fields
                self.updateAddressFields(for: self.country.selectedItem.rawData, address: .init())
            }
        }
    }

    /// Updates the "Billing same as shipping" checkbox and the default address used.
    /// - Note: This is a very specific method to handle the case where the merchant-provided default shipping address is updated after the AddressSectionElement is rendered
    public func updateBillingSameAsShippingDefaultAddress(_ defaultAddress: AddressDetails.Address) {
        // First, update the default address we use
        self.defaults.address = defaultAddress

        // Next, show/hide the checkbox if address is valid/invalid
        sameAsCheckbox.view.isHidden = defaultAddress == .init() || !countryCodes.contains(defaultAddress.country ?? "country doesn't exist")
        guard !sameAsCheckbox.view.isHidden else {
            // We're done if the checkbox is hidden
            return
        }

        // Finally...
        if sameAsCheckbox.isSelected {
            // ...update the fields with the default values if billing checkbox is shown and checked
            let index = self.country.items.firstIndex {
                $0.rawData == defaults.address.country ?? ""
            } ?? self.country.selectedIndex
            selectCountry(index: index, address: defaults.address)
        } else {
            // ...or select the checkbox if the address matches
            sameAsCheckbox.isSelected = displayedAddressEqualTo(address: defaultAddress)
        }
    }

    /// Selects a country and rebuilds its address fields using the country-specific minimum requirement.
    private func selectCountry(index: Int, address: AddressDetails.Address? = nil) {
        if country.selectedIndex != index {
            country.selectedIndex = index
        }
        updateAddressFields(for: countryCodes[index], address: address)
    }

    private func resolvedFieldsToCollect(for countryCode: String) -> FieldsToCollect {
        guard let countryMinimum = minimumFieldsToCollectByCountry[countryCode] else {
            return defaultFieldsToCollect
        }

        switch (defaultFieldsToCollect, countryMinimum) {
        case (.all, _), (_, .all):
            return .all
        case (.countryAndPostal, _), (_, .countryAndPostal):
            return .countryAndPostal
        case (.country, .country):
            return .country
        }
    }

    /// - Parameter address: Populates the new fields with the provided defaults, or the current fields' text if `nil`.
    private func updateAddressFields(
        for countryCode: String,
        address: AddressDetails.Address? = nil
    ) {
        // Create the new address fields' default text
        let address = address ?? AddressDetails.Address(
            city: city?.text,
            country: nil,
            line1: line1?.text,
            line2: line2?.text,
            postalCode: postalCode?.text,
            state: state?.rawData
        )

        // Get the address spec for the country and filter out unused fields
        let fieldsToCollect = resolvedFieldsToCollect(for: countryCode)
        let spec = addressSpecProvider.addressSpec(for: countryCode)
        let fieldOrdering = spec.fieldOrdering.filter {
            switch fieldsToCollect {
            case .all:
                return true
            case .country:
                return false
            case .countryAndPostal:
                if case .postal = $0 {
                    return true
                }
                return false
            }
        }
        let displayedFieldOrdering = fieldsToCollect == .all && autocompleteStyle.isCompact ? [] : fieldOrdering

        if fieldsToCollect == .all, autocompleteStyle.isCompact {
            autoCompleteLine = autoCompleteLine ?? DummyAddressLine(theme: theme, didTap: { [weak self] in self?.didTapAutocompleteButton() })
        } else {
            autoCompleteLine = nil
        }
        // Re-create the address fields
        if displayedFieldOrdering.contains(.line) {
            if fieldsToCollect == .all, autocompleteStyle.showsAccessory(for: countryCode) {
                line1 = TextFieldElement.Address.LineConfiguration(
                    lineType: .line1Autocompletable(didTapAutocomplete: { [weak self] in self?.didTapAutocompleteButton() }),
                    defaultValue: address.line1
                ).makeElement(theme: theme)
            } else {
                line1 = TextFieldElement.Address.makeLine1(defaultValue: address.line1, theme: theme)
            }
        } else {
            line1 = nil
        }
        line2 = displayedFieldOrdering.contains(.line) ?
            TextFieldElement.Address.makeLine2(defaultValue: address.line2, theme: theme) : nil
        city = displayedFieldOrdering.contains(.city) ?
        spec.makeCityElement(defaultValue: address.city, theme: theme) : nil
        state = displayedFieldOrdering.contains(.state) ?
        spec.makeStateElement(defaultValue: address.state,
                              stateDict: Dictionary(uniqueKeysWithValues: zip(spec.subKeys ?? [], spec.subLabels ?? [])),
                              theme: theme) : nil
        postalCode = displayedFieldOrdering.contains(.postal) ?
        spec.makePostalElement(countryCode: countryCode, defaultValue: address.postalCode, theme: theme) : nil

        // Order the address fields according to `displayedFieldOrdering`
        let addressFields: [Element?] = displayedFieldOrdering.reduce([]) { partialResult, fieldType in
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

        var initialElements: [Element?] = [name, country]
        initialElements.append(autoCompleteLine)
        let emailElement: [Element?] = [email]
        let phoneElement: [Element?] = [phone]
        addressSection.elements = (emailElement + phoneElement + initialElements + addressFields).compactMap { $0 }
    }

    /// Returns `true` iff all **displayed** address fields match the given `address`, treating `nil` and "" as equal.
    func displayedAddressEqualTo(address: AddressDetails.Address) -> Bool {
        var allDisplayedFieldsEqual = true
        if let city = city, city.text.nonEmpty != address.city?.nonEmpty {
           allDisplayedFieldsEqual = false
        }
        if country.selectedItem.rawData != address.country?.nonEmpty {
           allDisplayedFieldsEqual = false
        }
        if let line1 = line1, line1.text.nonEmpty != address.line1?.nonEmpty {
           allDisplayedFieldsEqual = false
        }
        if let line2 = line2, line2.text.nonEmpty != address.line2?.nonEmpty {
           allDisplayedFieldsEqual = false
        }
        if let postalCode = postalCode, postalCode.text.nonEmpty != address.postalCode?.nonEmpty {
           allDisplayedFieldsEqual = false
        }
        if let state = state, state.rawData.nonEmpty != address.state?.nonEmpty {
           allDisplayedFieldsEqual = false
        }
        return allDisplayedFieldsEqual
    }

}

private extension AddressSectionElement.AutocompleteStyle {
    var isCompact: Bool {
        switch self {
        case .compact:
            return true
        case .none, .expanded:
            return false
        }
    }

    func showsAccessory(for countryCode: String) -> Bool {
        switch self {
        case .expanded(let supportedCountries):
            return supportedCountries?.caseInsensitiveContains(countryCode) ?? true
        case .none, .compact:
            return false
        }
    }
}

// MARK: - Element
extension AddressSectionElement: Element {
    @discardableResult
    public func beginEditing() -> Bool {
        let firstInvalidNonDropDownElement = firstInvalidNonDropdownElement(elements: elements)

        // If first non-dropdown element is auto complete, don't do anything
        if firstInvalidNonDropDownElement === autoCompleteLine {
            return false
        }

        return firstInvalidNonDropDownElement?.beginEditing() ?? false
    }

    private func firstInvalidNonDropdownElement(elements: [Element]) -> Element? {
        for element in elements {
            if let sectionElement = element as? SectionElement,
               let firstInvalid = firstInvalidNonDropdownElement(elements: sectionElement.elements) {
                return firstInvalid
            }
            switch element.validationState {
            case .valid:
                continue
            case .invalid:
                if !(element is DropdownFieldElement) {
                    return element
                }
            }
        }
        return nil
    }
}

// MARK: - ElementDelegate
extension AddressSectionElement: ElementDelegate {
    public func didUpdate(element: Element) {
        if !sameAsCheckbox.view.isHidden, sameAsCheckbox.isSelected, !displayedAddressEqualTo(address: defaults.address) {
            // Deselect checkbox if the address != the shipping address (our `defaults`)
            sameAsCheckbox.isSelected = false
        }
        delegate?.didUpdate(element: self)
        didUpdate?(addressDetails)

        // Update the selected country in the phone element if the no defaults have been provided
        // and the phone number element hasn't been modified
        // to match the country picker if they don't match
        if let phone = phone,
            defaults.phone == nil,
            !phone.hasBeenModified
            && phone.countryDropdownElement.selectedIndex != country.selectedIndex {
            phone.selectCountry(index: country.selectedIndex, shouldUpdateDefaultNumber: true)
        }
    }
}

@_spi(STP) public extension AddressSectionElement.AddressDetails {
    init(
        billingAddress: BillingAddress,
        phone: String?,
        name: String? = nil,
        email: String? = nil
    ) {
        self.init(
            name: name ?? billingAddress.name,
            phone: phone,
            email: email,
            address: Address(
                city: billingAddress.city,
                country: billingAddress.countryCode,
                line1: billingAddress.line1,
                line2: billingAddress.line2,
                postalCode: billingAddress.postalCode,
                state: billingAddress.state
            )
        )
    }
}
