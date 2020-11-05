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

  static let localizedStripeStringUseMainBundle: Bool = {
    if STPBundleLocator.stripeResourcesBundle.preferredLocalizations.first
      != Bundle.main.preferredLocalizations.first
    {
      return true
    }
    return false
  }()

  class func localizedStripeString(forKey key: String) -> String {
    if languageOverride != nil {
      return testing_localizedStripeString(forKey: key)
    }
    let bundle =
      localizedStripeStringUseMainBundle ? Bundle.main : STPBundleLocator.stripeResourcesBundle

    let translation = bundle.localizedString(forKey: key, value: nil, table: nil)

    return translation
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
