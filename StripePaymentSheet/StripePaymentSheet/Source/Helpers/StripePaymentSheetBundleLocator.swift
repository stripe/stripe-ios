//
//  StripePaymentSheetBundleLocator.swift
//  StripePaymentSheet
//
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(InternalOnlyAPI) import StripeCore

/// :nodoc:
@_spi(InternalOnlyAPI) public final class StripePaymentSheetBundleLocator: BundleLocatorProtocol {
    public static let internalClass: AnyClass = StripePaymentSheetBundleLocator.self
    public static let bundleName = "StripePaymentSheetBundle"
    #if SWIFT_PACKAGE
    public static let spmResourcesBundle = Bundle.module
    #endif
    public static let resourcesBundle = StripePaymentSheetBundleLocator.computeResourcesBundle()
}
