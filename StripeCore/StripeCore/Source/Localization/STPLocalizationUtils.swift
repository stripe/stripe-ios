//
//  STPLocalizationUtils.swift
//  StripeCore
//
//  Created by Brian Dorfman on 8/11/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

import Foundation

@_spi(STP) public final class STPLocalizationUtils {
    /// Acts like NSLocalizedString but tries to find the string in the Stripe
    /// bundle first if possible.
    ///
    /// If the main app has a localization that we do not support, we want to switch
    /// to pulling strings from the main bundle instead of our own bundle so that
    /// users can add translations for our strings without having to fork the sdk.
    /// At launch, NSBundles' store what language(s) the user requests that they
    /// actually have translations for in `preferredLocalizations`.
    /// We compare our framework's resource bundle to the main app's bundle, and
    /// if their language choice doesn't match up we switch to pulling strings
    /// from the main bundle instead.
    /// This also prevents language mismatches. E.g. the user lists portuguese and
    /// then spanish as their preferred languages. The main app supports both so all its
    /// strings are in pt, but we support spanish so our bundle marks es as our
    /// preferred language and our strings are in es.
    /// If the main bundle doesn't have the correct string, we'll always fall back to
    /// using the Stripe bundle so we don't inadvertently show an untranslated string.
    static func localizedStripeStringUseMainBundle(
        bundleLocator: BundleLocatorProtocol.Type
    ) -> Bool {
        if bundleLocator.resourcesBundle.preferredLocalizations.first
            != Bundle.main.preferredLocalizations.first
        {
            return true
        }
        return false
    }

    static let UnknownString = "STPSTRINGNOTFOUND"

    public class func localizedStripeString(
        forKey key: String,
        bundleLocator: BundleLocatorProtocol.Type
    ) -> String {
        if languageOverride != nil {
            return testing_localizedStripeString(forKey: key, bundleLocator: bundleLocator)
        }
        if localizedStripeStringUseMainBundle(bundleLocator: bundleLocator) {
            // Per https://developer.apple.com/documentation/foundation/bundle/1417694-localizedstring,
            // iOS will give us an empty string if a string isn't found for the specified key.
            // Work around this by specifying an unknown sentinel string as the value. If we get that value back,
            // we know that the string wasn't present in the bundle.
            let userTranslation = Bundle.main.localizedString(
                forKey: key,
                value: UnknownString,
                table: nil
            )
            if userTranslation != UnknownString {
                return userTranslation
            }
        }

        return bundleLocator.resourcesBundle.localizedString(
            forKey: key,
            value: nil,
            table: nil
        )
    }

    // MARK: - Testing
    static var languageOverride: String?
    static func overrideLanguage(to string: String?) {
        STPLocalizationUtils.languageOverride = string
    }
    static func testing_localizedStripeString(
        forKey key: String,
        bundleLocator: BundleLocatorProtocol.Type
    ) -> String {
        var bundle = bundleLocator.resourcesBundle

        if let languageOverride = languageOverride {

            let lprojPath = bundle.path(forResource: languageOverride, ofType: "lproj")
            if let lprojPath = lprojPath {
                bundle = Bundle(path: lprojPath)!
            }
        }
        return bundle.localizedString(forKey: key, value: nil, table: nil)
    }
}

/// Use to explicitly ignore static analyzer warning:
/// "User-facing text should use localized string macro".
@inline(__always) @_spi(STP) public func STPNonLocalizedString(_ string: String) -> String {
    return string
}
