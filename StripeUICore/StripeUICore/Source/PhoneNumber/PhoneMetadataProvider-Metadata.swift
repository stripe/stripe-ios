//
//  PhoneMetadataProvider-Metadata.swift
//  StripeUICore
//
//  Created by Ramon Torres on 8/10/22.
//

import Foundation

extension PhoneMetadataProvider {

    /// Phone metadata entry.
    final class Metadata: Decodable {
        /// ISO 3166-1 alpha-2 country code.
        let region: String

        /// ITU-T country calling code.
        let code: String

        /// National trunk prefix.
        let trunkPrefix: String?

        /// Valid phone number length (excl. trunk prefix and calling code).
        let lengths: Set<Int>

        /// Available formats.
        let formats: [Format]

        /// Whether or not the metadata belongs to a NANP member.
        ///
        /// <https://en.wikipedia.org/wiki/North_American_Numbering_Plan>
        var isNANP: Bool { code == "+1" }

        /// Maximum phone number length (excl. trunk prefix and calling code).
        private(set) lazy var maxLength: Int = lengths.max() ?? 0

        init(
            region: String,
            code: String,
            trunkPrefix: String? = nil,
            lengths: Set<Int> = [],
            formats: [Format] = []
        ) {
            self.region = region
            self.code = code
            self.trunkPrefix = trunkPrefix
            self.lengths = lengths
            self.formats = formats
        }

        /// Returns the best formatter template for the given number.
        ///
        /// - Parameter number: Phone number.
        /// - Returns: Formatter template.
        func bestFormat(for number: String) -> String? {
            // Do not return a format for empty strings
            guard !number.isEmpty else { return nil }

            let hasTrunkPrefix = numberHasTrunkPrefix(number)
            let normalizedNumber = removeTrunkPrefixIfNeeded(number)

            if isNANP {
                // Skip heuristics for NANP territories.
                return hasTrunkPrefix
                    ? formats.first?.getOrMakeNationalTemplate(trunkPrefix: trunkPrefix)
                    : formats.first?.template
            }

            // We need at least 3 digits to be able to pick a format.
            guard normalizedNumber.count > 3 else {
                return nil
            }

            let targetMatcherIndex = max(normalizedNumber.count - 3, 0)
            let extent = NSRange(location: 0, length: normalizedNumber.count)

            let bestFormat = formats.first { format in
                guard format.matcherRegexes.count > 0 else {
                    // The format is unconstrained.
                    return true
                }

                let matcherIndex = min(targetMatcherIndex, format.matcherRegexes.count - 1)

                guard let regex = format.matcherRegexes[matcherIndex],
                      let match = regex.firstMatch(in: normalizedNumber, range: extent) else {
                    return false
                }

                // We must check that the regex matches the beginning of the number.
                // Some of the regexes can contain capture groups that match the middle
                // of the number.
                return match.range.location == 0
            }

            return hasTrunkPrefix
                ? bestFormat?.getOrMakeNationalTemplate(trunkPrefix: trunkPrefix)
                : bestFormat?.template
        }

        func removeTrunkPrefixIfNeeded(_ number: String) -> String {
            guard let trunkPrefix = trunkPrefix else {
                return number
            }

            return number.starts(with: trunkPrefix)
                ? String(number.dropFirst(trunkPrefix.count))
                : number
        }

        private func numberHasTrunkPrefix(_ number: String) -> Bool {
            guard let trunkPrefix = trunkPrefix else {
                return false
            }

            return number.starts(with: trunkPrefix)
        }
    }

}

// MARK: - Format

extension PhoneMetadataProvider.Metadata {

    /// Phone format.
    final class Format: Decodable {
        /// Default formatting template.
        let template: String

        /// Template to use when formatting with a national trunk prefix.
        let nationalTemplate: String?

        /// Array of regular expression patterns for matching a phone number to the format.
        let matchers: [String]

        /// Array of compiled regular expressions for matching.
        private(set) lazy var matcherRegexes: [NSRegularExpression?] = matchers.map {
            do {
                return try NSRegularExpression(pattern: $0)
            } catch {
                assertionFailure(error.localizedDescription)
                return nil
            }
        }

        /// Returns the national formatting template, or synthesizes if it doesn't exists.
        /// - Parameter trunkPrefix: Trunk prefix.
        /// - Returns: National formatting template.
        func getOrMakeNationalTemplate(trunkPrefix: String?) -> String {
            if let nationalTemplate = nationalTemplate {
                return nationalTemplate
            }

            guard let trunkPrefix = trunkPrefix else {
                // No trunk prefix provided.
                return template
            }

            let prefixTemplate = String(repeating: "#", count: trunkPrefix.count)
            // If the template begins with a digit, we don't need to add a space after trunk prefix.
            return template.first == "#"
                ? "\(prefixTemplate)\(template)"
                : "\(prefixTemplate) \(template)"
        }
    }

}
