//
//  STPPostalCodeInputTextFieldFormatter.swift
//  StripeiOS
//
//  Created by Cameron Sabol on 10/30/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import UIKit

class STPPostalCodeInputTextFieldFormatter: STPInputTextFieldFormatter {

    var countryCode: String? = Locale.autoupdatingCurrent.regionCode

    override func isAllowedInput(_ input: String, to string: String, at range: NSRange) -> Bool {
        guard super.isAllowedInput(input, to: string, at: range),
            input.rangeOfCharacter(from: .stp_invertedPostalCode) == nil,
            let range = Range(range, in: string)
        else {
            return false
        }

        let proposed = string.replacingCharacters(in: range, with: input)
        if countryCode == "US", proposed.count > 5 {
            return false
        }
        return STPPostalCodeValidator.validationState(
            forPostalCode: proposed, countryCode: countryCode) != .invalid
    }

    override func formattedText(
        from input: String, with defaultAttributes: [NSAttributedString.Key: Any]
    ) -> NSAttributedString {
        return NSAttributedString(
            string: STPPostalCodeValidator.formattedSanitizedPostalCode(
                from: input.trimmingCharacters(in: .whitespacesAndNewlines),
                countryCode: countryCode,
                usage: .billingAddress) ?? "",
            attributes: defaultAttributes)
    }
}
