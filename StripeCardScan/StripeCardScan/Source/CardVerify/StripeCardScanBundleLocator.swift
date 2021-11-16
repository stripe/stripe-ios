//
//  StripeCardScanBundleLocator.swift
//  StripeCardScan
//
//  Created by Sam King on 11/10/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeCore

/// :nodoc:
final class StripeCardScanBundleLocator: BundleLocatorProtocol {
    static let internalClass: AnyClass = StripeCardScanBundleLocator.self
    static let bundleName = "StripeCardScan"
    #if SWIFT_PACKAGE
        static let spmResourcesBundle = Bundle.module
    #endif
    static let resourcesBundle = StripeCardScanBundleLocator.computeResourcesBundle()
}

