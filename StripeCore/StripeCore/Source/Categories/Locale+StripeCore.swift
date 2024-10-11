//
//  Locale+StripeCore.swift
//  StripeCore
//
//  Created by David Estes on 11/20/23.
//

import Foundation

@_spi(STP) public extension Locale {
    /// Returns the regionCode, for visionOS compatibility
    /// We can remove this once we drop iOS 16
    var stp_regionCode: String? {
#if canImport(CompositorServices)
        return self.region?.identifier
        #else
        return self.regionCode
        #endif
    }

    var stp_currencyCode: String? {
        #if canImport(CompositorServices)
        return self.currency?.identifier
        #else
        return self.currencyCode
        #endif
    }

    var stp_languageCode: String? {
#if canImport(CompositorServices)
        return self.language.languageCode?.identifier
        #else
        return self.languageCode
        #endif
    }

    static var stp_isoRegionCodes: [String] {
#if canImport(CompositorServices)
        return self.Region.isoRegions.map { $0.identifier }
#else
        return self.isoRegionCodes
#endif
    }

    /// Returns the BCP 47(-ish) language tag representing the locale.
    ///
    /// The language tag is expected to be well-formed as log as the locale identifier contains a
    /// valid language code. For example:
    ///
    /// ```
    /// let locale = Locale(identifier: "fr_CA")
    /// locale.toLanguageTag() // -> "fr-CA"
    /// ```
    ///
    /// The following example returns `"-ES"`, even though `"und-ES"` will be the appropriate BCP 47 tag:
    ///
    /// ```
    /// let locale = Locale(identifier: "_ES")
    /// locale.toLanguageTag() // -> "-ES"
    /// ```
    /// All system iOS and macOS locales are expected to contain valid language codes.
    ///
    /// On iOS 16+, the device region may be different from the language region. When these are different,
    /// the device region is encoded at the end. The example below corresponds to:
    /// Language=English (UK) and Region=United States:
    ///
    /// ```
    /// let locale = Locale(identifier: "en_GB@rg=uszzzz")
    /// locale.toLanguageTag() // -> "en-GB-u-rg-uszzzz"
    /// ```
    ///
    func toLanguageTag() -> String {
        if #available(iOS 16, *) {
            return Locale.identifier(.bcp47, from: self.identifier)
        } else {
            // `canonicalLanguageIdentifier` returns an invalid locale string
            // with an '@' char on iOS 16+ when language region != device region.
            // Ex: Language=English (UK) and Region=United States -> "en-GB@rg=uszzzz"
            return Locale.canonicalLanguageIdentifier(from: self.identifier)
        }
    }
}
