//
//  STPPostalCodeInputTextFieldValidator.swift
//  StripePaymentsUI
//
//  Created by Cameron Sabol on 10/30/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
import UIKit

class STPPostalCodeInputTextFieldValidator: STPInputTextFieldValidator {

    override var defaultErrorMessage: String? {
        if countryCode?.uppercased() == "US" {
            return STPLocalizedString(
                "Your ZIP is invalid.",
                "Error message for when postal code in form is invalid (US only)"
            )
        } else {
            return STPLocalizedString(
                "Your postal code is invalid.",
                "Error message for when postal code in form is invalid"
            )
        }
    }

    override public var inputValue: String? {
        didSet {
            updateValidationState()
        }
    }

    var countryCode: String? = Locale.autoupdatingCurrent.stp_regionCode {
        didSet {
            updateValidationState()
        }
    }

    let postalCodeRequirement: STPPostalCodeRequirement

    required init(
        postalCodeRequirement: STPPostalCodeRequirement
    ) {
        self.postalCodeRequirement = postalCodeRequirement
        super.init()
    }

    private func updateValidationState() {

        switch STPPostalCodeValidator.validationState(
            forPostalCode: inputValue,
            countryCode: countryCode,
            with: postalCodeRequirement
        )
        {
        case .valid:
            validationState = .valid(message: nil)
        case .invalid:
            // Note: these don't actually happen (since we don't do offline validation, defaultErrorMessage is
            // primarily a backup for missing api error strings)
            validationState = .invalid(errorMessage: defaultErrorMessage)
        case .incomplete:
            var incompleteDescription: String?
            if let inputValue = inputValue, !inputValue.isEmpty {
                if countryCode?.uppercased() == "US" {
                    incompleteDescription = String.Localized.your_zip_is_incomplete
                } else {
                    incompleteDescription = String.Localized.your_postal_code_is_incomplete
                }
            }
            validationState = .incomplete(description: incompleteDescription)
        }
    }
}
