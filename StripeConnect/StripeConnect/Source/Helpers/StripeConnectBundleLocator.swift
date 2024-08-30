//
//  StripeConnectBundleLocator.swift
//  StripeConnect
//
//  Created by Chris Mays on 7/31/24.
//

import Foundation
@_spi(STP) import StripeCore

final class StripeConnectBundleLocator: BundleLocatorProtocol {
    static let internalClass: AnyClass = StripeConnectBundleLocator.self
    static let bundleName = "StripeConnectBundle"
    #if SWIFT_PACKAGE
    static let spmResourcesBundle = Bundle.module
    #endif
    static let resourcesBundle = StripeConnectBundleLocator.computeResourcesBundle()
}
