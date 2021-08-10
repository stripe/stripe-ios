//
//  StripeBundleLocator.swift
//  StripeiOS
//
//  Created by Mel Ludowise on 7/6/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeCore

final class StripeBundleLocator: BundleLocatorProtocol {
    static let internalClass: AnyClass = StripeBundleLocator.self
    static let bundleName = "Stripe"
    #if SWIFT_PACKAGE
        static let spmResourcesBundle: Bundle? = Bundle.module
    #else
        static let spmResourcesBundle: Bundle? = nil
    #endif
    static let resourcesBundle = StripeBundleLocator.computeResourcesBundle()
}
