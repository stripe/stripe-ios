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

        private(set) lazy var maxLength: Int = {
            return lengths.max() ?? 0
        }()

        /// Returns the best formatter template for the given number.
        ///
        /// - Parameter number: Phone number.
        /// - Returns: Formatter template.
        func bestFormat(for number: String) -> String? {
            // Do not return a format for empty strings
            guard !number.isEmpty else { return nil }

            guard formats.count > 1 else {
                // Skip heuristics for territories with a single format.
                return formats.first?.template
            }

            let hasTrunkPrefix = numberHasTrunkPrefix(number)
            let normalizedNumber = removeTrunkPrefixIfNeeded(number)

            let extent = NSRange(location: 0, length: normalizedNumber.count)

            // Find the first format that matches the beginning of the number.
            let format = formats.first { format in
                format.matcherRegex?.numberOfMatches(in: normalizedNumber, range: extent) == 1
            }

            return hasTrunkPrefix ? format?.nationalTemplate : format?.template
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

extension PhoneMetadataProvider.Metadata {

    final class Format: Decodable {
        let template: String
        let nationalTemplate: String?
        let matcher: String

        private(set) lazy var matcherRegex = try? NSRegularExpression(pattern: matcher)
    }

}
