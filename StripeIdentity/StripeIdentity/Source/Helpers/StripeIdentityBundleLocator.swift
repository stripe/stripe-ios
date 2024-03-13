//
//  StripeIdentityBundleLocator.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 7/13/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeCore

@_spi(STP) public final class StripeIdentityBundleLocator: BundleLocatorProtocol {
    @_spi(STP) public static let internalClass: AnyClass = StripeIdentityBundleLocator.self
    @_spi(STP) public static let bundleName = "StripeIdentityBundle"
    #if SWIFT_PACKAGE
    @_spi(STP) public static let spmResourcesBundle = Bundle.module
    #endif
    @_spi(STP) public static let resourcesBundle = StripeIdentityBundleLocator.computeResourcesBundle()
}
