//
//  STPLocalizedString.swift
//  StripeCardScan
//
//  Created by Sam King on 12/8/21.
//

import Foundation

@_spi(STP) import StripeCore

@inline(__always) func STPLocalizedString(_ key: String, _ comment: String?) -> String {
    return STPLocalizationUtils.localizedStripeString(forKey: key, bundleLocator: StripeCardScanBundleLocator.self)
}
