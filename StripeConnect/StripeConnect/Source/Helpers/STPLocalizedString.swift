//
//  STPLocalizedString.swift
//  StripeConnect
//
//  Created by Chris Mays on 7/31/24.
//

import Foundation
@_spi(STP) import StripeCore

@inline(__always) func STPLocalizedString(_ key: String, _ comment: String?) -> String {
    return STPLocalizationUtils.localizedStripeString(
        forKey: key,
        bundleLocator: StripeConnectBundleLocator.self
    )
}
