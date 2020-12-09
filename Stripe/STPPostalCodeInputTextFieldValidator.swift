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
                if countryCode?.uppercased() == "US" {
                    errorMessage = STPLocalizedString("Invalid zip code.", "Error message for when postal code in form is invalid (US only)")
                } else {
                    errorMessage = STPLocalizedString("Invalid postal code.", "Error message for when postal code in form is invalid")
                }
                validationState = .invalid(errorMessage: errorMessage)
            case .incomplete:
                var incompleteDescription: String? = nil
                if !inputValue.isEmpty {
                    if countryCode?.uppercased() == "US" {
                        incompleteDescription = STPLocalizedString("Incomplete zip code.", "Error message for when postal code in form is incomplete (US only)")
                    } else {
                        incompleteDescription = STPLocalizedString("Incomplete postal code.", "Error message for when postal code in form is incomplete")
                    }
                }
                validationState = .incomplete(description: incompleteDescription)
            }
        }
    }
}
