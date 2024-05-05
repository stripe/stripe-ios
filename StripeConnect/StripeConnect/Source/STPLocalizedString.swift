//
//  STPLocalizedString.swift
//  StripeConnect
//
//  Created by Mel Ludowise on 5/5/24.
//

@_spi(STP) import StripeCore

@inline(__always) func STPLocalizedString(_ key: String, _ comment: String?) -> String {
    return STPLocalizationUtils.localizedStripeString(
        forKey: key,
        bundleLocator: StripeConnectBundleLocator.self
    )
}
