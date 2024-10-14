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
    /// The language tag is expected to be well-formed as long as the locale identifier contains a
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
    /// locale.toLanguageTag() // -> "en-GB"
    /// ```
    ///
    func toLanguageTag() -> String {
        var tag = Locale.canonicalLanguageIdentifier(from: self.identifier)

        // Drop sub-tags or extended variants like `en-US@calendar=gregorian`
        // or `en-GB@rg=uszzzz`
        if let unextended = tag.split(separator: "@").first {
            tag = String(unextended)
        }

        /*
         iOS omits the language script when specifying:
         language=Chinese, Traditional and region=Hong Kong (China)

         Stripe's web and backend localization will default to Simplified Chinese
         (zh-Hans) if no script is specified, so insert the `Hant` script to
         ensure Traditional Chinese is returned.
         */
        if tag == "zh-HK" {
            tag = "zh-Hant-HK"
        }
        return tag
    }
}
