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
    static func countryFlagEmoji(for countryCode: String) -> String? {
        let capitalized = countryCode.uppercased()
        guard Locale.stp_isoRegionCodes.contains(capitalized) else {
            return nil
        }

        let unicodeScalars = capitalized.unicodeScalars.compactMap({ Unicode.Scalar($0.value + 127397) })
        guard unicodeScalars.count == 2 else {
            return nil
        }

        return String(String.UnicodeScalarView(unicodeScalars))

    }
}
