//
//  PhoneMetadataProvider-Format.swift
//  StripeUICore
//
//  Created by Ramon Torres on 8/19/22.
//

import Foundation

// MARK: - Format

extension PhoneMetadataProvider {

    /// Phone format.
    struct Format: Decodable {
        /// Default formatting template.
        let template: String

        /// Template to use when formatting with a national trunk prefix.
        let nationalTemplate: String?

        /// Array of regular expression patterns for matching a phone number to the format.
        let matchers: [String]

        private static let regexCache: NSCache<NSString, NSRegularExpression> = {
            let cache = NSCache<NSString, NSRegularExpression>()
            cache.countLimit = 30
            return cache
        }()

        var digits: Int {
            return template.filter({ $0 == "#" }).count
        }

        /// Array of compiled regular expressions for matching.
        var matcherRegexes: [NSRegularExpression?] {
            matchers.map { (matcher: String) in
                let key = matcher as NSString

                if let result = Self.regexCache.object(forKey: key) {
                    return result
                }

                do {
                    let regex = try NSRegularExpression(pattern: matcher)
                    Self.regexCache.setObject(regex, forKey: key)
                    return regex
                } catch {
                    assertionFailure(error.localizedDescription)
                    return nil
                }
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
