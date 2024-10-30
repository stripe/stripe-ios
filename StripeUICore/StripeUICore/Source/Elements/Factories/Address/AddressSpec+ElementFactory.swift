//
//  AddressSpec+ElementFactory.swift
//  StripeUICore
//
//  Created by Yuki Tokuhiro on 6/9/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation

/// Convenience methods to create address fields that are localized according to the AddressSpec
extension AddressSpec {
    func makeCityElement(defaultValue: String?, theme: ElementsAppearance = .default) -> TextFieldElement {
        return TextFieldElement.Address.CityConfiguration(
            label: cityNameType.localizedLabel,
            defaultValue: defaultValue,
            isOptional: !requiredFields.contains(.city)
        ).makeElement(theme: theme)
    }

    func makeStateElement(defaultValue: String?, stateDict: [String: String], theme: ElementsAppearance = .default) -> TextOrDropdownElement {
        // If no state dict just use a textfield for state
        if stateDict.isEmpty {
            return TextFieldElement.Address.StateConfiguration(
                label: stateNameType.localizedLabel,
                defaultValue: defaultValue,
                isOptional: !requiredFields.contains(.state)
            ).makeElement(theme: theme)
        }

        // Otherwise create a dropdown with the provided states
        let items = stateDict.map({DropdownFieldElement.DropdownItem(pickerDisplayName: $0.value,
                                                                     labelDisplayName: $0.value,
                                                                     accessibilityValue: $0.value,
                                                                     rawData: $0.key)}).sorted { $0.pickerDisplayName.string < $1.pickerDisplayName.string }

        let defaultIndex = items.firstIndex(where: {$0.rawData.lowercased() == defaultValue?.lowercased()
            || $0.pickerDisplayName.string.lowercased() == defaultValue?.lowercased()}) ?? 0

        return DropdownFieldElement(items: items,
                                    defaultIndex: defaultIndex,
                                    label: stateNameType.localizedLabel,
                                    theme: theme,
                                    didUpdate: nil)
    }

    func makePostalElement(countryCode: String, defaultValue: String?, theme: ElementsAppearance = .default) -> TextFieldElement {
        return TextFieldElement.Address.PostalCodeConfiguration(
            countryCode: countryCode,
            label: zipNameType.localizedLabel,
            defaultValue: defaultValue,
            isOptional: !requiredFields.contains(.postal)
        ).makeElement(theme: theme)
    }
}
