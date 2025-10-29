//
//  StripeCryptoOnrampBundleLocator.swift
//  StripeCryptoOnramp
//
//  Created by Mat Schmid on 8/14/25.
//

import Foundation
@_spi(STP) import StripeCore

@_spi(STP) public
final class StripeCryptoOnrampBundleLocator: BundleLocatorProtocol {
    public static let internalClass: AnyClass = StripeCryptoOnrampBundleLocator.self
    public static let bundleName = "StripeCryptoOnrampBundle"
    #if SWIFT_PACKAGE
    public static let spmResourcesBundle = Bundle.module
    #endif
    public static let resourcesBundle = StripeCryptoOnrampBundleLocator.computeResourcesBundle()
}
