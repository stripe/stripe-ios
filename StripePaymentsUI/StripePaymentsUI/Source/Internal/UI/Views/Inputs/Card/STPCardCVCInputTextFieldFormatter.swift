//
//  STPCardCVCInputTextFieldFormatter.swift
//  StripePaymentsUI
//
//  Created by Cameron Sabol on 10/22/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
import UIKit

class STPCardCVCInputTextFieldFormatter: STPNumericDigitInputTextFormatter {

    var cardBrand: STPCardBrand = .unknown

    override func isAllowedInput(_ input: String, to string: String, at range: NSRange) -> Bool {
        guard super.isAllowedInput(input, to: string, at: range) else {
            return false
        }

        let maxLength = STPCardValidator.maxCVCLength(for: cardBrand)
        if string.count + input.count > maxLength {
            return false
        }

        return true
    }

    override func formattedText(
        from input: String,
        with defaultAttributes: [NSAttributedString.Key: Any]
    ) -> NSAttributedString {
        let numeric = STPNumericStringValidator.sanitizedNumericString(for: input)
        return NSAttributedString(string: numeric, attributes: defaultAttributes)
    }
}
