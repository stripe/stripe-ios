//
//  StripeCoreBundleLocator.swift
//  StripeCore
//
//  Created by Mel Ludowise on 7/6/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation

final class StripeCoreBundleLocator: BundleLocatorProtocol {
    static let internalClass: AnyClass = StripeCoreBundleLocator.self
    static let bundleName = "StripeCoreBundle"
    #if SWIFT_PACKAGE
        static let spmResourcesBundle = Bundle.module
    #endif
    static let resourcesBundle = StripeCoreBundleLocator.computeResourcesBundle()
}
