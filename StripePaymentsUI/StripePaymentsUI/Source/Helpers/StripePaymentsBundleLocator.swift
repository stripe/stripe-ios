//
//  StripePaymentsBundleLocator.swift
//  StripePaymentsUI
//
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeCore

/// :nodoc:
@_spi(STP) public final class StripePaymentsUIBundleLocator: BundleLocatorProtocol {
    public static let internalClass: AnyClass = StripePaymentsUIBundleLocator.self
    public static let bundleName = "StripePaymentsUIBundle"
    #if SWIFT_PACKAGE
        public static let spmResourcesBundle = Bundle.module
    #endif
    public static let resourcesBundle = StripePaymentsUIBundleLocator.computeResourcesBundle()
}
