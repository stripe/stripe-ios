//
//  StripeIdentityBundleLocator.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 7/13/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeCore

final class StripeIdentityBundleLocator: BundleLocatorProtocol {
    static let internalClass: AnyClass = StripeIdentityBundleLocator.self
    static let bundleName = "StripeIdentity"
    #if SWIFT_PACKAGE
        static let spmResourcesBundle = Bundle.module
    #endif
    static let resourcesBundle = StripeIdentityBundleLocator.computeResourcesBundle()
}
