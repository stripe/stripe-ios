//
//  StripeBundleLocator.swift
//  StripeiOS
//
//  Created by Mel Ludowise on 7/6/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeCore

/// :nodoc:
@_spi(STP) public final class StripeBundleLocator: BundleLocatorProtocol {
    public static let internalClass: AnyClass = StripeBundleLocator.self
    public static let bundleName = "Stripe"
    #if SWIFT_PACKAGE
    public static let spmResourcesBundle = Bundle.module
    #endif
    public static let resourcesBundle = StripeBundleLocator.computeResourcesBundle()
}
