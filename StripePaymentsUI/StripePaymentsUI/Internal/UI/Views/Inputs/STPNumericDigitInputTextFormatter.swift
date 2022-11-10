//
//  STPNumericDigitInputTextFormatter.swift
//  StripePaymentsUI
//
//  Created by Cameron Sabol on 10/22/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

@_spi(STP) import StripeCore
import UIKit

class STPNumericDigitInputTextFormatter: STPInputTextFieldFormatter {
    let allowedFormattingCharacterSet: CharacterSet?

    internal init(
        allowedFormattingCharacterSet: CharacterSet?
    ) {
        self.allowedFormattingCharacterSet = allowedFormattingCharacterSet
        super.init()
    }

    override convenience init() {
        self.init(allowedFormattingCharacterSet: nil)
    }

    override func isAllowedInput(_ input: String, to string: String, at range: NSRange) -> Bool {
        guard super.isAllowedInput(input, to: string, at: range) else {
            return false
        }

        let unformattedInput: String
        if let allowedFormattingCharacterSet = allowedFormattingCharacterSet {
            unformattedInput = input.stp_stringByRemovingCharacters(
                from: allowedFormattingCharacterSet
            )
        } else {
            unformattedInput = input
        }

        return STPNumericStringValidator.isStringNumeric(unformattedInput)
    }

    override func formattedText(
        from input: String,
        with defaultAttributes: [NSAttributedString.Key: Any]
    ) -> NSAttributedString {
        let numeric = STPNumericStringValidator.sanitizedNumericString(for: input)
        return NSAttributedString(string: numeric, attributes: defaultAttributes)
    }
}
