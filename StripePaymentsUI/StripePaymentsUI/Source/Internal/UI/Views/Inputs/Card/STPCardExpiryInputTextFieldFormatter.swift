//
//  STPCardExpiryInputTextFieldFormatter.swift
//  StripePaymentsUI
//
//  Created by Cameron Sabol on 10/22/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
import UIKit

class STPCardExpiryInputTextFieldFormatter: STPInputTextFieldFormatter {

    override func isAllowedInput(_ input: String, to string: String, at range: NSRange) -> Bool {
        guard super.isAllowedInput(input, to: string, at: range),
            let range = Range(range, in: string)
        else {
            return false
        }

        let proposed = string.replacingCharacters(in: range, with: input)
            .stp_stringByRemovingCharacters(from: .whitespaces)
        var proposedComponents = proposed.split(separator: "/").map({ String($0) }).filter({
            !$0.isEmpty
        })
        if let firstComponent = proposedComponents.first,
            firstComponent == proposed
        {
            // we don't have a separator, so go by index
            proposedComponents = [
                proposed.stp_safeSubstring(to: 2), proposed.stp_safeSubstring(from: 2),
            ].filter({ !$0.isEmpty })
        }

        if proposedComponents.count > 2 {
            return false
        } else if proposedComponents.first(where: {
            !STPNumericStringValidator.isStringNumeric(String($0))
        }) != nil {
            return false
        } else if let firstComponent = proposedComponents.first {
            if proposedComponents.count > 1 && firstComponent.count > 2 {
                return false
            } else if firstComponent.count < 2 && proposedComponents.count > 1 {
                return false
            } else if proposedComponents.count > 1 {
                let yearComponent = proposedComponents[1]
                if yearComponent.count > 4 {
                    return false
                } else if yearComponent.count > 2 && !string.isEmpty {
                    // we only allow pasting of 4 digit years, which will be formatted
                    return false
                }
            }
            return true
        } else {
            return false
        }
    }

    override func formattedText(
        from input: String,
        with defaultAttributes: [NSAttributedString.Key: Any]
    ) -> NSAttributedString {
        var numericInput = STPNumericStringValidator.sanitizedNumericString(for: input)

        // A MM/YY starting with 2-9 must be a single digit month; prepend a 0
        if let firstNumber = numericInput.first?.wholeNumberValue,
            (2...9).contains(firstNumber)
        {
            numericInput = "0".appending(numericInput)
        }

        if numericInput.count > 2 {
            numericInput =
                numericInput.stp_safeSubstring(to: 2) + "/"
                + numericInput.stp_safeSubstring(from: 2)
        }

        let expirationString = STPStringUtils.expirationDateString(from: numericInput)
        return NSAttributedString(string: expirationString ?? "", attributes: defaultAttributes)
    }
}
