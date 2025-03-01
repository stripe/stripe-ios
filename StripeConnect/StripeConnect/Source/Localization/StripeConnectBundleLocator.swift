//
//  StripeConnectBundleLocator.swift
//  StripeConnect
//
//  Created by Chris Mays on 2/25/25.
//

import Foundation
@_spi(STP) import StripeCore

/// :nodoc:
final class StripeConnectBundleLocator: BundleLocatorProtocol {
    static let internalClass: AnyClass = StripeConnectBundleLocator.self
    static let bundleName = "StripeConnectBundle"
    #if SWIFT_PACKAGE
        static let spmResourcesBundle = Bundle.module
    #endif
    static let resourcesBundle = StripeConnectBundleLocator.computeResourcesBundle()
}
