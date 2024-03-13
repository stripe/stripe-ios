//
//  StripePaymentsBundleLocator.swift
//  StripePayments
//
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeCore

/// :nodoc:
@_spi(STP) public final class StripePaymentsBundleLocator: BundleLocatorProtocol {
    public static let internalClass: AnyClass = StripePaymentsBundleLocator.self
    public static let bundleName = "StripePaymentsBundle"
    #if SWIFT_PACKAGE
        public static let spmResourcesBundle = Bundle.module
    #endif
    public static let resourcesBundle = StripePaymentsBundleLocator.computeResourcesBundle()
}
