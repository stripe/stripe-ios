//
//  NSAttributedString+Extensions.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 9/22/22.
//

import Foundation
import UIKit

// MARK: - Markdown Bold

extension NSMutableAttributedString {

    /// Adds `boldFont` as an attribute in all the places that are surrounded by asterisks (ex. `**bold string here**).
    ///
    /// For example, `Click **here**` returns `Click here` with "here" being applied the `boldFont` as attribute.
    func addBoldFontAttributesByMarkdownRules(boldFont: UIFont) {
        guard
            // The regex will find all occurrances of tokens formatted as: `**bold string here**`
            let regularExpression = try? NSRegularExpression(
                pattern: #"\*\*[^\*\n]+\*\*"#,
                options: NSRegularExpression.Options(rawValue: 0)
            )
        else {
            return
        }

        while let textCheckingResult = regularExpression.firstMatch(
            in: string,
            range: NSRange(location: 0, length: string.count)
        ) {
            // range where `**bold string here**` token is
            let markdownBoldRange = textCheckingResult.range
            // the string `**bold string here**`
            let markdownBoldString = attributedSubstring(from: markdownBoldRange)

            // the string `bold string here`
            let nonmarkdownBoldString = markdownBoldString.extractStringInAsterisks()

            if let nonmarkdownBoldString = nonmarkdownBoldString?.mutableCopy() as? NSMutableAttributedString {
                // apply a "bold font attribute to the string `bold string here`
                nonmarkdownBoldString
                    .addAttribute(
                        .font,
                        value: boldFont,
                        range: NSRange(location: 0, length: nonmarkdownBoldString.length)
                    )

                replaceCharacters(in: markdownBoldRange, with: nonmarkdownBoldString)
            }
        }
    }
}

extension NSAttributedString {

    /// Extracts a substring out of the first set of asterisks.
    ///
    /// For example,  `Bold Text` out of `**Bold Text**`.
    fileprivate func extractStringInAsterisks() -> NSAttributedString? {
        guard
            let regularExpression = try? NSRegularExpression(
                pattern: #"(?<=\*\*)[^\*\n]*(?=\*\*)"#,
                options: NSRegularExpression.Options(rawValue: 0)
            )
        else {
            return nil
        }
        guard
            let range = regularExpression.firstMatch(in: string, range: NSRange(location: 0, length: string.count))?
                .range
        else {
            return nil
        }
        return attributedSubstring(from: range)
    }
}
