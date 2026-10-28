//
//  StripeIdentityBundleLocator.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 7/13/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(InternalOnlyAPI) import StripeCore

@_spi(InternalOnlyAPI) public final class StripeIdentityBundleLocator: BundleLocatorProtocol {
    @_spi(InternalOnlyAPI) public static let internalClass: AnyClass = StripeIdentityBundleLocator.self
    @_spi(InternalOnlyAPI) public static let bundleName = "StripeIdentityBundle"
    #if SWIFT_PACKAGE
    @_spi(InternalOnlyAPI) public static let spmResourcesBundle = Bundle.module
    #endif
    @_spi(InternalOnlyAPI) public static let resourcesBundle = StripeIdentityBundleLocator.computeResourcesBundle()
}
