//
//  STPCardExpiryInputTextFieldValidator.swift
//  StripeiOS
//
//  Created by Cameron Sabol on 10/22/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import UIKit

class STPCardExpiryInputTextFieldValidator: STPInputTextFieldValidator {

    override var defaultErrorMessage: String? {
        return STPLocalizedString(
            "Your card's expiration date is invalid.",
            "Error message for card details form when expiration date is invalid")
    }

    public var expiryStrings: (month: String, year: String)? {
        guard let inputValue = inputValue else {
            return nil
        }
        let numericInput = STPNumericStringValidator.sanitizedNumericString(for: inputValue)
        let monthString = numericInput.stp_safeSubstring(to: 2)
        let yearString = numericInput.stp_safeSubstring(from: 2)
        if monthString.count == 2 && yearString.count == 2 {
            return (month: monthString, year: yearString)
        } else {
            return nil
        }
    }

    override public var inputValue: String? {
        didSet {
            guard let inputValue = inputValue else {
                validationState = .incomplete(description: nil)
                return
            }

            let numericInput = STPNumericStringValidator.sanitizedNumericString(for: inputValue)
            let monthString = numericInput.stp_safeSubstring(to: 2)
            let yearString = numericInput.stp_safeSubstring(from: 2)

            let monthState = STPCardValidator.validationState(forExpirationMonth: monthString)
            let yearState = STPCardValidator.validationState(
                forExpirationYear: yearString, inMonth: monthString)

            if monthState == .valid && yearState == .valid {
                validationState = .valid(message: nil)
            } else if monthState == .invalid && yearState == .invalid {
                // TODO: We should be more specific here e.g. "Your card's expiration year is in the past."
                validationState = .invalid(errorMessage: defaultErrorMessage)
            } else if monthState == .invalid {
                validationState = .invalid(errorMessage: STPLocalizedString("Your card's expiration month is invalid.", "String to describe an invalid month in expiry date."))
            } else if yearState == .invalid {
                validationState = .invalid(errorMessage: STPLocalizedString("Your card's expiration year is invalid.", "String to describe an invalid year in expiry date."))
            } else {
                validationState = .incomplete(
                    description: !inputValue.isEmpty
                        ? STPLocalizedString(
                            "Your card's expiration date is incomplete.",
                            "Error message for card details form when expiration date isn't entered completely"
                        ) : nil)
            }
        }
    }
}
