//
//  StripeScanBundleLocator.swift
//  StripeScan
//
//  Created by Sam King on 11/10/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeCore

/// :nodoc:
final class StripeScanBundleLocator: BundleLocatorProtocol {
    static let internalClass: AnyClass = StripeScanBundleLocator.self
    static let bundleName = "StripeScan"
    #if SWIFT_PACKAGE
        static let spmResourcesBundle = Bundle.module
    #endif
    static let resourcesBundle = StripeScanBundleLocator.computeResourcesBundle()
}

