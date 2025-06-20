//
//  STPLocalizedString.swift
//  StripeFinancialConnectionsLite
//
//  Created by Mat Schmid on 6/20/25.
//

import Foundation
@_spi(STP) import StripeCore

@inline(__always) func STPLocalizedString(_ key: String, _ comment: String?) -> String {
    return STPLocalizationUtils.localizedStripeString(
        forKey: key,
        bundleLocator: StripeFinancialConnectionsLiteBundleLocator.self
    )
}
