//
//  STPCardExpiryInputTextFieldValidator.swift
//  StripePaymentsUI
//
//  Created by Cameron Sabol on 10/22/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
import UIKit

class STPCardExpiryInputTextFieldValidator: STPInputTextFieldValidator {

    override var defaultErrorMessage: String? {
        return String.Localized.your_cards_expiration_date_is_invalid
    }

    public var expiryStrings: (month: String, year: String)? {
        guard let inputValue = inputValue else {
            return nil
        }
        let numericInput = STPNumericStringValidator.sanitizedNumericString(for: inputValue)
        let monthString = numericInput.stp_safeSubstring(to: 2)
        var yearString = numericInput.stp_safeSubstring(from: 2)

        // prepend "20" to ensure we provide a 4 digit year, this is to be consistent with Checkout
        if yearString.count == 2 {
            let centuryLeadingDigits = Int(
                floor(Double(Calendar(identifier: .iso8601).component(.year, from: Date())) / 100)
            )

            yearString = "\(centuryLeadingDigits)\(yearString)"
        }

        if monthString.count == 2 && yearString.count == 4 {
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
                forExpirationYear: yearString,
                inMonth: monthString
            )

            if monthState == .valid && yearState == .valid {
                validationState = .valid(message: nil)
            } else if monthState == .invalid && yearState == .invalid {
                // TODO: We should be more specific here e.g. "Your card's expiration year is in the past."
                validationState = .invalid(errorMessage: defaultErrorMessage)
            } else if monthState == .invalid {
                validationState = .invalid(
                    errorMessage: String.Localized.your_cards_expiration_month_is_invalid
                )
            } else if yearState == .invalid {
                validationState = .invalid(
                    errorMessage: String.Localized.your_cards_expiration_year_is_invalid
                )
            } else {
                validationState = .incomplete(
                    description: !inputValue.isEmpty
                        ? String.Localized.your_cards_expiration_date_is_incomplete : nil
                )
            }
        }
    }
}
