//
//  StripeElementsBundleLocator.swift
//  StripeElements
//
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeCore

/// :nodoc:
@_spi(STP) public final class StripeElementsBundleLocator: BundleLocatorProtocol {
    public static let internalClass: AnyClass = StripeElementsBundleLocator.self
    public static let bundleName = "StripeElementsBundle"
    #if SWIFT_PACKAGE
    public static let spmResourcesBundle = Bundle.module
    #endif
    public static let resourcesBundle = StripeElementsBundleLocator.computeResourcesBundle()
}
