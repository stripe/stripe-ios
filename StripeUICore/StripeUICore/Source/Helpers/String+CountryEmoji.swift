//
//  String+CountryEmoji.swift
//  StripeUICore
//
//  Created by Cameron Sabol on 9/30/21.
//

import UIKit

extension String {
    static func countryFlagEmoji(for countryCode: String) -> String? {
        let capitalized = countryCode.uppercased()
        guard Locale.isoRegionCodes.contains(capitalized) else {
            return nil
        }
        
        let unicodeScalars = capitalized.unicodeScalars.compactMap({ Unicode.Scalar($0.value + 127397) })
        guard unicodeScalars.count == 2 else {
            return nil
        }
                
        return String(String.UnicodeScalarView(unicodeScalars))
        
    }
}

