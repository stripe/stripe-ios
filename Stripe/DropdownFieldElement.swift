//
//  DropdownFieldElement.swift
//  StripeiOS
//
//  Created by Yuki Tokuhiro on 6/17/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation
import UIKit
@_spi(STP) import StripeCore

/**
 A textfield whose input view is a `UIPickerView` with a list of the strings.
 */
class DropdownFieldElement {
    typealias DidUpdateSelectedIndex = (Int) -> Void

    weak var delegate: ElementDelegate?
    lazy var dropdownView: DropdownFieldView = {
        return DropdownFieldView(
            items: items,
            defaultIndex: defaultIndex,
            label: label,
            delegate: self
        )
    }()
    let items: [String]
    let label: String
    let defaultIndex: Int
    var selectedIndex: Int {
        return dropdownView.selectedRow
    }
    private var previouslySelectedIndex: Int
    var didUpdate: DidUpdateSelectedIndex?

    init(
        items: [String],
        defaultIndex: Int = 0,
        label: String,
        didUpdate: DidUpdateSelectedIndex? = nil
    ) {
        self.label = label
        self.items = items
        self.defaultIndex = defaultIndex
        self.previouslySelectedIndex = defaultIndex
        self.didUpdate = didUpdate
    }
}

// MARK: Element

extension DropdownFieldElement: Element {
    var view: UIView {
        return dropdownView
    }
}

// MARK: - DropdownFieldDelegate

extension DropdownFieldElement: DropdownFieldViewDelegate {
    func didFinish(_ dropDownFieldView: DropdownFieldView) {
        if previouslySelectedIndex != selectedIndex {
            didUpdate?(selectedIndex)
        }
        previouslySelectedIndex = selectedIndex
        delegate?.didFinishEditing(element: self)
    }
}

// MARK: - Helper

extension DropdownFieldElement {
    /**
     Initializes a DropdownFieldElement that displays `countryCodes` by their localized display names and defaults to the user's country.
     */
    convenience init(
        label: String,
        countryCodes: [String],
        defaultCountry: String? = nil,
        locale: Locale = Locale.current
    ) {
        let countryDisplayStrings = countryCodes.map {
            locale.localizedString(forRegionCode: $0) ?? $0
        }
        let defaultCountry = defaultCountry ?? locale.regionCode ?? ""
        let defaultCountryIndex = countryCodes.firstIndex(of: defaultCountry) ?? 0
        self.init(
            items: countryDisplayStrings,
            defaultIndex: defaultCountryIndex,
            label: String.Localized.country_or_region
        )
    }
}
