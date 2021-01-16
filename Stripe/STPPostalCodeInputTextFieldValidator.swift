//
//  STPPostalCodeInputTextFieldValidator.swift
//  StripeiOS
//
//  Created by Cameron Sabol on 10/30/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import UIKit

class STPPostalCodeInputTextFieldValidator: STPInputTextFieldValidator {
    
    var countryCode: String? = Locale.autoupdatingCurrent.regionCode

    override public var inputValue: String? {
        didSet {
            guard let inputValue = inputValue,
                  !inputValue.isEmpty else {
                validationState = .incomplete(description: nil)
                return
            }
            
            switch STPPostalCodeValidator.validationState(forPostalCode: inputValue, countryCode: countryCode) {
            case .valid:
                validationState = .valid(message: nil)
            case .invalid:
                var errorMessage: String? = nil
                // Note: these don't actually happen
                if countryCode?.uppercased() == "US" {
                    errorMessage = STPLocalizedString("Your ZIP is invalid.", "Error message for when postal code in form is invalid (US only)")
                } else {
                    errorMessage = STPLocalizedString("Your postal code is invalid.", "Error message for when postal code in form is invalid")
                }
                validationState = .invalid(errorMessage: errorMessage)
            case .incomplete:
                var incompleteDescription: String? = nil
                if !inputValue.isEmpty {
                    if countryCode?.uppercased() == "US" {
                        incompleteDescription = STPLocalizedString("Your ZIP is incomplete.", "Error message for when ZIP code in form is incomplete (US only)")
                    } else {
                        incompleteDescription = STPLocalizedString("Your postal code is incomplete.", "Error message for when postal code in form is incomplete")
                    }
                }
                validationState = .incomplete(description: incompleteDescription)
            }
        }
    }
}
