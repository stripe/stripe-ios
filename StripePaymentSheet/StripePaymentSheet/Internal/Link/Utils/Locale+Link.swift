//
//  Locale+Link.swift
//  StripeiOS
//
//  Created by Ramon Torres on 8/3/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation

extension Locale {

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
    ///
    /// All system iOS and macOS locales are expected to contain valid language codes.
    func toLanguageTag() -> String {
        return Locale.canonicalLanguageIdentifier(from: self.identifier)
    }

}
