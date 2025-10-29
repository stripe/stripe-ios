//
//  STPStringUtils.swift
//  StripePaymentSheet
//
//  Created by Brian Dorfman on 9/7/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeCore

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

typealias STPTaggedSubstringCompletionBlock = (String?, NSRange) -> Void
typealias STPTaggedSubstringsCompletionBlock = (String, [String: NSValue]) -> Void
extension STPStringUtils {
    enum Error: Swift.Error {
        case tagMissing
        case tagsNotApplied
    }
    /// Takes a string with the named html-style tags, removes the tags,
    /// and then calls the completion block with the modified string and the range
    /// in it that the tag would have enclosed.
    /// E.g. Passing in @"Test <b>string</b>" with tag @"b" would call completion
    /// with @"Test string" and NSMakeRange(5,6).
    /// Completion is always called, location of range is NSNotFound with the unmodified
    /// string if a match could not be found.
    /// - Parameters:
    ///   - string:     The string with tagged substrings.
    ///   - tag:        The tag to search for.
    ///   - completion: The string with the named tag removed and the range of the
    /// substring it covered.
    @objc(parseRangeFromString:withTag:completion:) class func parseRange(
        from string: String,
        withTag tag: String,
        completion: STPTaggedSubstringCompletionBlock
    ) {
        let startingTag = "<\(tag)>"
        let startingTagRange = (string as NSString?)?.range(of: startingTag)
        if startingTagRange?.location == NSNotFound {
            completion(string, startingTagRange!)
            return
        }

        var finalString: String?
        if let startingTagRange = startingTagRange {
            finalString = (string as NSString?)?.replacingCharacters(in: startingTagRange, with: "")
        }
        let endingTag = "</\(tag)>"
        let endingTagRange = (finalString as NSString?)?.range(of: endingTag)
        if endingTagRange?.location == NSNotFound {
            completion(string, endingTagRange!)
            return
        }

        if let endingTagRange = endingTagRange {
            finalString = (finalString as NSString?)?.replacingCharacters(
                in: endingTagRange, with: "")
        }
        let finalTagRange = NSRange(
            location: startingTagRange?.location ?? 0,
            length: (endingTagRange?.location ?? 0) - (startingTagRange?.location ?? 0))

        completion(finalString, finalTagRange)
    }

    /// Like `parseRangeFromString:withTag:completion:` but you can pass in a set
    /// of unique tags to get the ranges for and it will return you the mapping.
    /// E.g. Passing @"<a>Test</a> <b>string</b>" with the tag set [a, b]
    /// will get you a completion block dictionary that looks like
    /// @{ @"a" : NSMakeRange(0,4),
    /// @"b" : NSMakeRange(5,6) }
    /// - Parameters:
    ///   - string:     The string with tagged substrings.
    ///   - tags:       The tags to search for.
    ///   - completion: The string with the named tags removed and the ranges of the
    /// substrings they covered (wrapped in NSValue)
    /// @warning Doesn't currently support overlapping tag ranges because that's
    /// complicated and we don't need it at the moment.
    @objc(parseRangesFromString:withTags:completion:) class func parseRanges(
        from string: String,
        withTags tags: Set<String>,
        completion: STPTaggedSubstringsCompletionBlock
    ) {
        var interiorRangesToTags: [NSValue: String] = [:]
        var tagsToRange: [String: NSValue] = [:]

        for tag in tags {
            self.parseRange(
                from: string,
                withTag: tag
            ) { _, tagRange in
                if tagRange.location == NSNotFound {
                    tagsToRange[tag] = NSValue(range: tagRange)
                } else {
                    let interiorRange = NSRange(
                        location: tagRange.location + tag.count + 2,
                        length: tagRange.length)
                    interiorRangesToTags[NSValue(range: interiorRange)] = tag
                }
            }
        }
        guard !hasOverlappingRanges(ranges: interiorRangesToTags) else {
            let strippedString = string.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression, range: nil)
            completion(strippedString, [:])
            return
        }

        let sortedRanges = interiorRangesToTags.keys.sorted { (obj1, obj2) -> Bool in
            let range1 = obj1.rangeValue
            let range2 = obj2.rangeValue
            return range1.location < range2.location
        }

        var modifiedString = string

        var deletedCharacters = 0

        for rangeValue in sortedRanges {
            let tag = interiorRangesToTags[rangeValue]
            var interiorTagRange = rangeValue.rangeValue
            if interiorTagRange.location != NSNotFound {
                interiorTagRange.location -= deletedCharacters
                let beginningTagLength = (tag?.count ?? 0) + 2
                let beginningTagRange = NSRange(
                    location: interiorTagRange.location - beginningTagLength,
                    length: beginningTagLength)

                if let subRange = Range<String.Index>(beginningTagRange, in: modifiedString) {
                    modifiedString.removeSubrange(subRange)
                }
                interiorTagRange.location -= beginningTagLength
                deletedCharacters += beginningTagLength

                let endingTagLength = beginningTagLength + 1
                let endingTagRange = NSRange(
                    location: interiorTagRange.location + interiorTagRange.length,
                    length: endingTagLength)

                if let subRange = Range<String.Index>(endingTagRange, in: modifiedString) {
                    modifiedString.removeSubrange(subRange)
                }
                deletedCharacters += endingTagLength
                tagsToRange[tag!] = NSValue(range: interiorTagRange)
            }
        }

        completion(modifiedString, tagsToRange)
    }

    class func hasOverlappingRanges(ranges: [NSValue: String]) -> Bool {
        let allRanges = ranges.keys
        var map: Set<Int> = []
        for range in allRanges {
            let rangeValue = range.rangeValue

            guard rangeValue.location != NSNotFound else {
                continue
            }

            for i in 0..<rangeValue.length {
                let markedIndex = rangeValue.location+i
                if map.contains(markedIndex) {
                    return true
                } else {
                    map.insert(markedIndex)
                }
            }
        }
        return false
    }

    class func applyLinksToString(template: String, links: [String: URL]) -> NSMutableAttributedString {
        let formattedString = NSMutableAttributedString()
        var numberOfLinksApplied = 0
        STPStringUtils.parseRanges(from: template, withTags: Set<String>(links.keys)) { string, matches in
            formattedString.append(NSAttributedString(string: string))
            for (tag, range) in matches {
                guard range.rangeValue.location != NSNotFound else {
                    let errorAnalytic = ErrorAnalytic(event: .unexpectedPaymentSheetError,
                                                      error: Error.tagMissing,
                                                      additionalNonPIIParams: ["template": template,
                                                                               "tag_missing": tag,
                                                                              ])
                    STPAnalyticsClient.sharedClient.log(analytic: errorAnalytic)
                    stpAssertionFailure("Tag '<\(tag)>' not found")
                    continue
                }

                if let url = links[tag] {
                    numberOfLinksApplied += 1
                    formattedString.addAttributes([.link: url], range: range.rangeValue)
                }
            }
        }
        if numberOfLinksApplied != links.count {
            let errorAnalytic = ErrorAnalytic(event: .unexpectedPaymentSheetError,
                                              error: Error.tagsNotApplied,
                                              additionalNonPIIParams: ["template": template,
                                                                       "links": links,
                                                                      ])
            STPAnalyticsClient.sharedClient.log(analytic: errorAnalytic)
            stpAssertionFailure("Failed to apply links '\(links)' to '\(template)'")
        }
        return formattedString
    }
}
