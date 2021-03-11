//
//  STPLocalizationUtils.swift
//  Stripe
//
//  Created by Brian Dorfman on 8/11/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

import Foundation

class STPLocalizationUtils: NSObject {
    /// Acts like NSLocalizedString but tries to find the string in the Stripe
    /// bundle first if possible.
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
    /// using the Stripe bundle so we don't inadvertantly show an untranslated string.

    static let localizedStripeStringUseMainBundle: Bool = {
        if STPBundleLocator.stripeResourcesBundle.preferredLocalizations.first
            != Bundle.main.preferredLocalizations.first
        {
            return true
        }
        return false
    }()

    static let UnknownString = "STPStringNotFound"

    class func localizedStripeString(forKey key: String) -> String {
        if languageOverride != nil {
            return testing_localizedStripeString(forKey: key)
        }
        if localizedStripeStringUseMainBundle {
            // Per https://developer.apple.com/documentation/foundation/bundle/1417694-localizedstring,
            // iOS will give us an empty string if a string isn't found for the specified key.
            // Work around this by specifying an unknown sentinel string as the value. If we get that value back,
            // we know that the string wasn't present in the bundle.
            let userTranslation = Bundle.main.localizedString(
                forKey: key, value: UnknownString, table: nil)
            if userTranslation != UnknownString {
                return userTranslation
            }
        }

        return STPBundleLocator.stripeResourcesBundle.localizedString(
            forKey: key, value: nil, table: nil)
    }

    // MARK: - Shared Strings
    // Localized strings that are used in multiple contexts. Collected here to avoid re-translation
    class func localizedNameString() -> String {
        return STPLocalizedString("Name", "Label for Name field on form")
    }

    class func localizedEmailString() -> String {
        return STPLocalizedString("Email", "Label for Email field on form")
    }

    class func localizedBankAccountString() -> String {
        return STPLocalizedString(
            "Bank Account", "Label for Bank Account selection or detail entry form")
    }

    class func localizedPhoneString() -> String {
        return STPLocalizedString("Phone", "Caption for Phone field on address form")
    }

    class func localizedAddressLine1String() -> String {
        return STPLocalizedString("Address", "Caption for Address field on address form")
    }

    class func localizedAddressLine2String() -> String {
        return STPLocalizedString(
            "Apt.", "Caption for Apartment/Address line 2 field on address form")
    }

    class func localizedCityString() -> String {
        return STPLocalizedString("City", "Caption for City field on address form")
    }

    class func localizedStateString(for countryCode: String?) -> String {
        switch countryCode {
        case "US":
            return STPLocalizedString(
                "State",
                "Caption for State field on address form (only countries that use state , like United States)"
            )
        case "CA":
            return STPLocalizedString(
                "Province",
                "Caption for Province field on address form (only countries that use province, like Canada)"
            )
        case "GB":
            return STPLocalizedString(
                "County",
                "Caption for County field on address form (only countries that use county, like United Kingdom)"
            )
        default:
            return STPLocalizedString(
                "State / Province / Region",
                "Caption for generalized state/province/region field on address form (not tied to a specific country's format)"
            )
        }
    }

    class func localizedPostalCodeString(for countryCode: String?) -> String {
        return countryCode == "US"
            ? STPLocalizedString(
                "ZIP Code",
                "Caption for Zip Code field on address form (only shown when country is United States only)"
            )
            : STPLocalizedString(
                "Postal Code",
                "Caption for Postal Code field on address form (only shown in countries other than the United States)"
            )
    }

    class func localizedCountryString() -> String {
        return STPLocalizedString("Country", "Caption for Country field on address form")
    }

    // Testing
    static var languageOverride: String?
    class func overrideLanguage(to string: String?) {
        STPLocalizationUtils.languageOverride = string
    }
    class func testing_localizedStripeString(forKey key: String) -> String {
        var bundle = STPBundleLocator.stripeResourcesBundle

        if let languageOverride = languageOverride {

            let lprojPath = bundle.path(forResource: languageOverride, ofType: "lproj")
            if let lprojPath = lprojPath {
                bundle = Bundle(path: lprojPath)!
            }
        }
        return bundle.localizedString(forKey: key, value: nil, table: nil)
    }
}

/// Use to explicitly ignore static analyzer warning: "User-facing text should use localized string macro"
@inline(__always) func STPNonLocalizedString(_ string: String) -> String {
    return string
}
