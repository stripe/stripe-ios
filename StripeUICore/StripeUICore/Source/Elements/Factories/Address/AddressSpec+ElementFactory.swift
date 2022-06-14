//
//  AddressSpec+ElementFactory.swift
//  StripeUICore
//
//  Created by Yuki Tokuhiro on 6/9/22.
//

import Foundation

/// Convenience methods to create address fields that are localized according to the AddressSpec
extension AddressSpec {
    func makeCityElement(defaultValue: String?) -> TextFieldElement {
        return TextFieldElement.Address.CityConfiguration(
            label: cityNameType.localizedLabel,
            defaultValue: defaultValue,
            isOptional: !requiredFields.contains(.city)
        ).makeElement()
    }
    
    func makeStateElement(defaultValue: String?) -> TextFieldElement {
        return TextFieldElement.Address.StateConfiguration(
            label: stateNameType.localizedLabel,
            defaultValue: defaultValue,
            isOptional: !requiredFields.contains(.state)
        ).makeElement()
    }
    
    func makePostalElement(countryCode: String, defaultValue: String?) -> TextFieldElement {
        return TextFieldElement.Address.PostalCodeConfiguration(
            countryCode: countryCode,
            label: zipNameType.localizedLabel,
            defaultValue: defaultValue,
            isOptional: !requiredFields.contains(.postal)
        ).makeElement()
    }
}
