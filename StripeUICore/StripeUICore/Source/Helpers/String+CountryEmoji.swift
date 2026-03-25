//
//  String+CountryEmoji.swift
//  StripeUICore
//
//  Created by Cameron Sabol on 9/30/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

@_spi(STP) import StripeCore
import UIKit

@_spi(STP) public extension String {
    /// Flag emoji for a known country code, or `nil` for non-countries like "EU".
    static func countryFlagEmoji(for countryCode: String) -> String? {
        let capitalized = countryCode.uppercased()
        guard Locale.stp_isoRegionCodes.contains(capitalized) else {
            return nil
        }
        return regionFlagEmoji(for: capitalized)
    }

    /// Flag emoji for any two-letter region code, including "EU" and other
    /// non-country codes that `countryFlagEmoji(for:)` rejects.
    static func regionFlagEmoji(for regionCode: String) -> String? {
        let uppercased = regionCode.uppercased()
        let scalars = uppercased.unicodeScalars.compactMap { Unicode.Scalar($0.value + 127397) }
        guard scalars.count == 2 else {
            return nil
        }
        return String(String.UnicodeScalarView(scalars))
    }
}
