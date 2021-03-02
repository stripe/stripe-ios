//
//  STPCardNumberInputTextFieldFormatter.swift
//  StripeiOS
//
//  Created by Cameron Sabol on 10/22/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import UIKit

class STPCardNumberInputTextFieldFormatter: STPNumericDigitInputTextFormatter {

    convenience init() {
        self.init(allowedFormattingCharacterSet: CharacterSet.whitespaces)
    }

    override func isAllowedInput(_ input: String, to string: String, at range: NSRange) -> Bool {
        guard super.isAllowedInput(input, to: string, at: range),
            let range = Range(range, in: string)
        else {
            return false
        }
        let proposed = string.replacingCharacters(in: range, with: input)
        let unformattedProposed = STPNumericStringValidator.sanitizedNumericString(for: proposed)

        var maxLength = STPBINRange.maxCardNumberLength()

        let hasCompleteMetadataForCardNumber = STPBINRange.hasBINRanges(
            forPrefix: unformattedProposed)
        if hasCompleteMetadataForCardNumber {
            let brand = STPCardValidator.brand(forNumber: unformattedProposed)
            maxLength = STPCardValidator.maxLength(for: brand)
        }

        if unformattedProposed.count > maxLength {
            return false
        }

        return true
    }

    override func formattedText(
        from input: String, with defaultAttributes: [NSAttributedString.Key: Any]
    ) -> NSAttributedString {
        let numeric = STPNumericStringValidator.sanitizedNumericString(for: input)
        let attributed = NSMutableAttributedString(string: numeric, attributes: defaultAttributes)

        let cardNumberFormat = STPCardValidator.cardNumberFormat(forCardNumber: attributed.string)

        var index = 0
        for segmentLength in cardNumberFormat {
            var segmentIndex = 0

            while index < (attributed.length) && segmentIndex < Int(segmentLength.uintValue) {
                if index + 1 != attributed.length
                    && segmentIndex + 1 == Int(segmentLength.uintValue)
                {
                    attributed.addAttribute(
                        .kern,
                        value: NSNumber(value: 5),
                        range: NSRange(location: index, length: 1))
                } else {
                    attributed.addAttribute(
                        .kern,
                        value: NSNumber(value: 0),
                        range: NSRange(location: index, length: 1))
                }

                index += 1
                segmentIndex += 1
            }
        }

        return NSAttributedString(attributedString: attributed)
    }
}
