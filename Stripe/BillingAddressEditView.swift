//
//  BillingAddressEditView.swift
//  StripeiOS
//
//  Created by Yuki Tokuhiro on 2/1/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation
import UIKit

protocol BillingAddressEditViewDelegate: AnyObject {
    func didUpdate(_ billingAddressEditView: BillingAddressEditView)
}

/// A view that collects billing address details
// TODO: This is hardcoded to collect the entire address but should probably be refactored to allow e.g. only name
class BillingAddressEditView: UIView {
    // MARK: - Static helper methods
    static func makePostalCodeField() -> STPPostalCodeInputTextField {
        return STPPostalCodeInputTextField()
    }
    static func makeCountryPickerField() -> STPCountryPickerInputField {
        STPCountryPickerInputField()
    }
    static func makeStateField() -> STPGenericInputTextField {
        let placeholderText = STPLocalizationUtils.localizedStateString(
            for: Locale.autoupdatingCurrent.regionCode)
        return STPGenericInputTextField(
            placeholder: placeholderText, textContentType: .addressState)
    }
    static func makeLine1Field() -> STPGenericInputTextField {
        let placeholderText = STPLocalizedString(
            "Address line 1", "Address line 1 placeholder for billing address form.")
        return STPGenericInputTextField(
            placeholder: placeholderText, textContentType: .streetAddressLine1,
            keyboardType: .numbersAndPunctuation)
    }
    static func makeLine2Field() -> STPGenericInputTextField {
        let placeholderText = STPLocalizedString(
            "Address line 2 (optional)", "Address line 2 placeholder for billing address form.")
        return STPGenericInputTextField(
            placeholder: placeholderText, textContentType: .streetAddressLine2,
            keyboardType: .numbersAndPunctuation, optional: true)
    }
    static func makeCityField() -> STPGenericInputTextField {
        return STPGenericInputTextField(
            placeholder: STPLocalizationUtils.localizedCityString(), textContentType: .addressCity)
    }

    // MARK: - BillingAddressEditView
    weak var delegate: BillingAddressEditViewDelegate?

    /// If any field is incomplete or invalid, returns nil.
    var billingDetails: STPPaymentMethodBillingDetails? {
        let billingDetails = STPPaymentMethodBillingDetails()
        let address = STPPaymentMethodAddress()

        if !postalCodeField.isHidden {
            if case .valid = postalCodeField.validationState {
                address.postalCode = postalCodeField.postalCode
            } else {
                return nil
            }
        }

        if case .valid = countryPickerField.validationState {
            address.country = countryPickerField.inputValue
        } else {
            return nil
        }

        if let stateField = stateField {
            if case .valid = stateField.validationState {
                address.state = stateField.inputValue
            } else {
                return nil
            }
        }

        if let line1Field = line1Field {
            if case .valid = line1Field.validationState {
                address.line1 = line1Field.inputValue
            } else {
                return nil
            }
        }
        if let line2Field = line2Field {
            if case .valid = line2Field.validationState {
                address.line2 = line2Field.inputValue
            } else {
                return nil
            }
        }

        if let cityField = cityField {
            if case .valid = cityField.validationState {
                address.city = cityField.inputValue
            } else {
                return nil
            }
        }

        billingDetails.address = address
        return billingDetails
    }

    // MARK: -
    private let postalCodeField: STPPostalCodeInputTextField = STPPostalCodeInputTextField()
    private let countryPickerField: STPCountryPickerInputField = STPCountryPickerInputField()
    private let stateField: STPGenericInputTextField?
    private let line1Field: STPGenericInputTextField?
    private let line2Field: STPGenericInputTextField?
    private let cityField: STPGenericInputTextField?

    required init() {
        stateField = Self.makeStateField()
        line1Field = Self.makeLine1Field()
        line2Field = Self.makeLine2Field()
        cityField = Self.makeCityField()
        let rows = [
            // Country selector
            [countryPickerField],
            // Address line 1
            [line1Field!],
            // Address line 2
            [line2Field!],
            // City, Postal code
            [cityField!, postalCodeField],
            // State
            [stateField!],
        ]
        let title = STPLocalizedString(
            "Billing address", "Billing address section title for card form entry.")
        let billingSection = STPFormView.Section(rows: rows, title: title, accessoryButton: nil)
        let billingForm = STPFormView(sections: [billingSection])
        super.init(frame: .zero)
        billingSection.rows.forEach({ $0.forEach({ $0.addObserver(self) }) })
        addAndPinSubview(billingForm)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/// :nodoc:
extension BillingAddressEditView: STPFormInputValidationObserver {
    func validationDidUpdate(
        to state: STPValidatedInputState, from previousState: STPValidatedInputState,
        for unformattedInput: String?, in input: STPFormInput
    ) {
        delegate?.didUpdate(self)
    }
}
