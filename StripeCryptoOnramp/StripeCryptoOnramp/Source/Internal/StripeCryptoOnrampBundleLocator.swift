//
//  StripeCryptoOnrampBundleLocator.swift
//  StripeCryptoOnramp
//
//  Created by Mat Schmid on 8/14/25.
//

import Foundation
@_spi(STP) import StripeCore

final class StripeCryptoOnrampBundleLocator: BundleLocatorProtocol {
    static let internalClass: AnyClass = StripeCryptoOnrampBundleLocator.self
    static let bundleName = "StripeCryptoOnrampBundle"
    #if SWIFT_PACKAGE
    static let spmResourcesBundle = Bundle.module
    #endif
    static let resourcesBundle = StripeCryptoOnrampBundleLocator.computeResourcesBundle()
}
