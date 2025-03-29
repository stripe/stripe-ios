//
//  STPStringUtils.swift
//  StripePaymentsUI
//
//  Created by Brian Dorfman on 9/7/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

import Foundation

@_spi(STP) public class STPStringUtils: NSObject {
    // This code was adapted from Stripe.js
    /// Reformats an expiration date with a four-digit year to one with a two digit year.
    /// Ex: `01/2021` to `01/21`.
    static let expirationDateStringRegex: NSRegularExpression = {
        return try! NSRegularExpression(
            pattern: "^(\\d{2}\\D{1,3})(\\d{1,4})?",
            options: []
        )
    }()

    @objc(expirationDateStringFromString:) @_spi(STP) public class func expirationDateString(
        from string: String?
    )
        -> String?
    {
        guard let string = string else {
            return nil
        }
        guard
            let result = expirationDateStringRegex.matches(
                in: string,
                options: [],
                range: NSRange(location: 0, length: string.count)
            ).first
        else {
            return string
        }
        if result.numberOfRanges > 1 && result.range(at: 2).length == 4 {
            // If a 4-digit year was pasted, shorten it to the last 2 digits
            var range = result.range(at: 2)
            range.length = 2
            range.location = (range.location) + 2
            let month = (string as NSString).substring(with: result.range(at: 1))
            let year = (string as NSString).substring(with: range)
            return "\(month)\(year)"
        }

        return string
    }

    static let stringMayContainExpirationDateRegex: NSRegularExpression? = {
        return try! NSRegularExpression(
            pattern: "^(\\d{2}\\D{1,3})(\\d{1,4})?",
            options: []
        )
    }()

    /// Returns YES if the string is likely to contain something formatted similar to an expiration date.
    /// It doesn't confirm that the expiration date is valid, or that it is even a date.
    @_spi(STP) public class func stringMayContainExpirationDate(_ string: String?) -> Bool {
        let result = stringMayContainExpirationDateRegex?.matches(
            in: string ?? "",
            options: [],
            range: NSRange(location: 0, length: string?.count ?? 0)
        ).first
        return result != nil && (result?.numberOfRanges ?? 0) > 0
    }

    static let slashFormattedExpirationDateRegex: NSRegularExpression? = {
        return try? NSRegularExpression(pattern: #"\b(\d{2})/(\d{2,4})\b"#)
    }()

    /// Returns a sanitized expiration date (in "0101" format) from a string.
    /// This differs from the existing expiration date parser, as it only looks for dates formatted by slashes.
    /// This is only intended for OCR use, as we'll often get messy strings like "Exp 01/20 Verification Code 123"
    @_spi(STP) public class func sanitizedExpirationDateFromOCRString(_ string: String) -> String? {
        guard let regex = slashFormattedExpirationDateRegex,
              let match = regex.firstMatch(in: string, range: NSRange(string.startIndex..., in: string)),
              match.numberOfRanges >= 3,
              let monthRange = Range(match.range(at: 1), in: string),
              let yearRange = Range(match.range(at: 2), in: string) else {
            return nil
        }

        let monthStr = String(string[monthRange])
        let yearStr = String(string[yearRange])

        // Combine month and year into MMYY format
        let sanitizedExpiration = monthStr + yearStr.suffix(2)
        return sanitizedExpiration
    }
}
