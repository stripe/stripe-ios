//
//  STPPostalCodeInputTextFieldValidator.swift
//  StripeiOS
//
//  Created by Cameron Sabol on 10/30/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import UIKit

class STPPostalCodeInputTextFieldValidator: STPInputTextFieldValidator {

    override var defaultErrorMessage: String? {
        if countryCode?.uppercased() == "US" {
            return STPLocalizedString(
                "Your ZIP is invalid.",
                "Error message for when postal code in form is invalid (US only)")
        } else {
            return STPLocalizedString(
                "Your postal code is invalid.",
                "Error message for when postal code in form is invalid")
        }
    }

    override public var inputValue: String? {
        didSet {
            updateValidationState()
        }
    }

    var countryCode: String? = Locale.autoupdatingCurrent.regionCode {
        didSet {
            updateValidationState()
        }
    }

    private func updateValidationState() {
        guard let inputValue = inputValue,
            !inputValue.isEmpty
        else {
            validationState = .incomplete(description: nil)
            return
        }

        switch STPPostalCodeValidator.validationState(
            forPostalCode: inputValue, countryCode: countryCode)
        {
        case .valid:
            validationState = .valid(message: nil)
        case .invalid:
            // Note: these don't actually happen (since we don't do offline validation, defaultErrorMessage is
            // primarily a backup for missing api error strings)
            validationState = .invalid(errorMessage: defaultErrorMessage)
        case .incomplete:
            var incompleteDescription: String? = nil
            if !inputValue.isEmpty {
                if countryCode?.uppercased() == "US" {
                    incompleteDescription = STPLocalizedString(
                        "Your ZIP is incomplete.",
                        "Error message for when ZIP code in form is incomplete (US only)")
                } else {
                    incompleteDescription = STPLocalizedString(
                        "Your postal code is incomplete.",
                        "Error message for when postal code in form is incomplete")
                }
            }
            validationState = .incomplete(description: incompleteDescription)
        }
    }
}
