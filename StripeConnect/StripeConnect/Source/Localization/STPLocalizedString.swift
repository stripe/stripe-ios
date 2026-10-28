//
//  STPLocalizedString.swift
//  StripeConnect
//
//  Created by Chris Mays on 2/25/25.
//

import Foundation
@_spi(InternalOnlyAPI) import StripeCore

@inline(__always) func STPLocalizedString(_ key: String, _ comment: String?) -> String {
    return STPLocalizationUtils.localizedStripeString(
        forKey: key,
        bundleLocator: StripeConnectBundleLocator.self
    )
}
