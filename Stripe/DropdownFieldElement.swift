//
//  DropdownFieldElement.swift
//  StripeiOS
//
//  Created by Yuki Tokuhiro on 6/17/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation
import UIKit

/**
 A textfield whose input view is a `UIPickerView` with a list of the strings.
 */
class DropdownFieldElement {
    typealias ParamsUpdater = (IntentConfirmParams, Int) -> IntentConfirmParams
    
    var delegate: ElementDelegate?
    lazy var dropdownView: DropdownFieldView = {
        return DropdownFieldView(items: items, accessibilityLabel: accessibilityLabel)
    }()
    let items: [String]
    let accessibilityLabel: String
    var selectedIndex: Int {
        return dropdownView.selectedRow
    }
    let paramsUpdater: ParamsUpdater
    
    // Note(yuki): I tried using ReferenceWritableKeyPath instead of the closure, but ran into issues w/ optional chaining
    init(items: [String], accessibilityLabel: String, paramsUpdater: @escaping ParamsUpdater) {
        self.accessibilityLabel = accessibilityLabel
        self.items = items
        self.paramsUpdater = paramsUpdater
    }
}

// MARK: Element

extension DropdownFieldElement: Element {
    func updateParams(params: IntentConfirmParams) -> IntentConfirmParams? {
        guard !dropdownView.isHidden else {
            return params
        }
        return paramsUpdater(params, selectedIndex)
    }
    
    var validationState: ElementValidationState {
        return .valid
    }
    
    var view: UIView {
        return dropdownView
    }
}

// MARK: - Helper

extension DropdownFieldElement {
    /**
     Initializes a DropdownFieldElement that displays `countryCodes` alphabetically by their localized display names,
     and puts the user's country first.
     
     - Parameter paramsUpdater: The string argument is the selected country's code
     */
    convenience init(
        countryCodes: Set<String>,
        locale: Locale = Locale.current,
        paramsUpdater: @escaping (IntentConfirmParams, String) -> IntentConfirmParams
    ) {
        typealias Country = (code: String, localizedDisplayName: String)

        let orderedCountries = Array(countryCodes)
            .map {
                Country(
                    code: $0,
                    localizedDisplayName: locale.localizedString(forRegionCode: $0) ?? $0
                )
            }
            .sorted { a, b in
                if locale.regionCode == a.code {
                    return true
                } else {
                    return a.localizedDisplayName < b.localizedDisplayName
                }
        }
        let paramsUpdater: ParamsUpdater = { params, selectedIndex in
            // Map the selected index to the associated country code
            paramsUpdater(params, orderedCountries[selectedIndex].code)
        }
        self.init(
            items: orderedCountries.map({ $0.localizedDisplayName }),
            accessibilityLabel: STPLocalizedString("Country or region", "Country selector and postal code entry form header title"),
            paramsUpdater: paramsUpdater
        )
    }
}
