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

            let hasTrunkPrefix = numberHasTrunkPrefix(number)
            let normalizedNumber = removeTrunkPrefixIfNeeded(number)
            let isCompleteNumber = lengths.contains(normalizedNumber.count)

            guard formats.count > 1 else {
                // Skip heuristics and always use the available format.
                return hasTrunkPrefix
                    ? formats.first?.getOrMakeNationalTemplate()
                    : formats.first?.template
            }

            var candidates = formats.filter { format in
                switch format.trunkPrefixRule {
                case .required:
                    return hasTrunkPrefix
                case .disallowed where isCompleteNumber:
                    return !hasTrunkPrefix
                default:
                    return true
                }
            }

            print(candidates)

            let patternBaseIndex = max(normalizedNumber.count - 3, 0)

            var acc: String = .init()

            for character in normalizedNumber {
                acc.append(character)

                guard acc.count >= 3 else { continue }

                let extent = NSRange(location: 0, length: acc.count)

                candidates = candidates.filter({ format in
                    let matcherIndex = min(patternBaseIndex, format.matcherRegexes.count - 1)
                    guard let regex = format.matcherRegexes[matcherIndex] else { return false }
                    debugPrint(regex.numberOfMatches(in: acc, range: extent))
                    return regex.numberOfMatches(in: acc, range: extent) == 1
                })

                print(acc)
                print(candidates.map { $0.template })
            }

            return hasTrunkPrefix
                ? candidates.first?.getOrMakeNationalTemplate()
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
        enum TrunkPrefixRule: String, Decodable {
            case required
            case allowed
            case disallowed
        }

        let template: String
        let nationalTemplate: String?
        let matchers: [String]
        let trunkPrefixRule: TrunkPrefixRule

        private(set) lazy var numberOfDigits: Int = template.filter({ $0 == "#"}).count

        private(set) lazy var matcherRegexes: [NSRegularExpression?] = matchers.map {
            do {
                return try NSRegularExpression(pattern: $0)
            } catch {
                assertionFailure(error.localizedDescription)
                return nil
            }
        }

        func getOrMakeNationalTemplate() -> String {
            if let nationalTemplate = nationalTemplate {
                return nationalTemplate
            }

            // If the template begins with a digit, we don't need to add a space after trunk prefix.
            return template.first == "#"
                ? "#\(template)"
                : "# \(template)"
        }
    }

}

extension PhoneMetadataProvider.Metadata.Format: CustomStringConvertible {
    var description: String {
        return [
            "Format(",
            "  template=\(template)",
            "  trunkPrefixRule=\(trunkPrefixRule.rawValue)",
            ")"
        ].joined(separator: "\n")
    }
}
