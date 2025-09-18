//
//  STPLocalizedString.swift
//  StripeCryptoOnramp
//
//  Created by Mat Schmid on 9/16/25.
//

import Foundation
@_spi(STP) import StripeCore

@inline(__always) func STPLocalizedString(_ key: String, _ comment: String?) -> String {
    return STPLocalizationUtils.localizedStripeString(
        forKey: key,
        bundleLocator: StripeCryptoOnrampBundleLocator.self
    )
}
