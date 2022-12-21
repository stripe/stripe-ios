//
//  String+Localized.swift
//  StripeiOS
//
//  Created by Mel Ludowise on 7/6/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripePaymentsUI
@_spi(STP) import StripeUICore

// MARK: - Legacy strings

/// Legacy strings
extension StripeSharedStrings {
    static func localizedPostalCodeString(for countryCode: String?) -> String {
        return countryCode == "US"
            ? String.Localized.zip : String.Localized.postal_code
    }
}
