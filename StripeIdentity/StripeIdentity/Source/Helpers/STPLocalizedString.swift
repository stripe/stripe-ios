//
//  STPLocalizedString.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 7/13/21.
//

@_spi(STP) import StripeCore

@inline(__always) func STPLocalizedString(_ key: String, _ comment: String?) -> String {
    return STPLocalizationUtils.localizedStripeString(forKey: key, bundleLocator: StripeIdentityBundleLocator.self)
}
