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
    typealias ParamsUpdater = (IntentConfirmParams, Int) -> IntentConfirmParams
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
    let paramsUpdater: ParamsUpdater
    var didUpdate: DidUpdateSelectedIndex?

    // Note(yuki): I tried using ReferenceWritableKeyPath instead of the closure, but ran into issues w/ optional chaining
    init(
        items: [String],
        defaultIndex: Int = 0,
        label: String,
        paramsUpdater: @escaping ParamsUpdater,
        didUpdate: DidUpdateSelectedIndex? = nil
    ) {
        self.label = label
        self.items = items
        self.defaultIndex = defaultIndex
        self.previouslySelectedIndex = defaultIndex
        self.paramsUpdater = paramsUpdater
        self.didUpdate = didUpdate
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
     Initializes a DropdownFieldElement that displays `countryCodes` alphabetically by their localized display names and defaults to the user's country.
     - Parameter paramsUpdater: Defaults to setting `billingDetails.address.country`
     */
    convenience init(
        label: String,
        countryCodes: [String],
        locale: Locale = Locale.current,
        paramsUpdater: ParamsUpdater? = nil
    ) {
        let paramsUpdater = paramsUpdater ?? { params, index  in
            let billing = params.paymentMethodParams.billingDetails ?? STPPaymentMethodBillingDetails()
            let address = billing.address ?? STPPaymentMethodAddress()
            address.country = countryCodes[index]
            params.paymentMethodParams.billingDetails = billing
            return params
        }
        let countryDisplayStrings = countryCodes.map {
            locale.localizedString(forRegionCode: $0) ?? $0
        }
        let defaultCountry = locale.regionCode ?? ""
        let defaultCountryIndex = countryCodes.firstIndex(of: defaultCountry) ?? 0
        self.init(
            items: countryDisplayStrings,
            defaultIndex: defaultCountryIndex,
            label: String.Localized.country_or_region,
            paramsUpdater: paramsUpdater
        )
    }
}
