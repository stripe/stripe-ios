//
//  PhoneMetadataProvider-Metadata.swift
//  StripeUICore
//
//  Created by Ramon Torres on 8/10/22.
//

import Foundation

extension PhoneMetadataProvider {

    final class Metadata: Decodable {
        let region: String
        let prefix: String
        let trunkPrefix: String?
        let lengths: Set<Int>
        let formats: [Format]

        var isNANP: Bool { prefix == "+1" }

        private(set) lazy var maxLength: Int = {
            return lengths.max() ?? 0
        }()

        init(
            region: String,
            prefix: String,
            trunkPrefix: String? = nil,
            lengths: Set<Int> = [],
            formats: [Format] = []
        ) {
            self.region = region
            self.prefix = prefix
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

            guard normalizedNumber.count > 3 else {
                return nil
            }

            let targetMatcherIndex = max(normalizedNumber.count - 3, 0)
            let extent = NSRange(location: 0, length: normalizedNumber.count)

            let candidates = formats.filter({ format in
                let matcherIndex = min(targetMatcherIndex, format.matcherRegexes.count - 1)

                let regex = format.matcherRegexes[matcherIndex]
                guard let match = regex?.firstMatch(in: normalizedNumber, range: extent) else {
                    return false
                }

                // We must check that the regex matches the beginning of the number.
                // Some of the regexes can contain capture groups that match the middle
                // of the number.
                return match.range.location == 0
            })

            return hasTrunkPrefix
                ? candidates.first?.getOrMakeNationalTemplate(trunkPrefix: trunkPrefix)
                : candidates.first?.template
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

    final class Format: Decodable {
        let template: String
        let nationalTemplate: String?
        let matchers: [String]

        private(set) lazy var matcherRegexes: [NSRegularExpression?] = matchers.map {
            do {
                return try NSRegularExpression(pattern: $0)
            } catch {
                assertionFailure(error.localizedDescription)
                return nil
            }
        }

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
