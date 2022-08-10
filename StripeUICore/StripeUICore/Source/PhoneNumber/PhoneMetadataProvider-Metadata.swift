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
        let lengths: Set<Int>
        let formats: [Format]

        init(region: String, prefix: String, lengths: Set<Int>, formats: [Format]) {
            self.region = region
            self.prefix = prefix
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

            let extent = NSRange(location: 0, length: number.count)

            // Find the first format that matches the beginning of the number.
            let format = formats.first { format in
                format.matcherRegex?.numberOfMatches(in: number, range: extent) == 1
            }

            return format?.template
        }
    }

}

extension PhoneMetadataProvider.Metadata {

    final class Format: Decodable {
        let template: String
        let matcher: String

        private(set) lazy var matcherRegex: NSRegularExpression? =
            try? NSRegularExpression(pattern: matcher)
    }

}
