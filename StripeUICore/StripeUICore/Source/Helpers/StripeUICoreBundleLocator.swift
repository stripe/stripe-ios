//
//  StripeUICoreBundleLocator.swift
//  StripeUICore
//
//  Created by Mel Ludowise on 9/8/21.
//

import Foundation
@_spi(STP) import StripeCore

@_spi(STP) public final class StripeUICoreBundleLocator: BundleLocatorProtocol {
    public static let internalClass: AnyClass = StripeUICoreBundleLocator.self
    public static let bundleName = "StripeUICore"
    #if SWIFT_PACKAGE
    public static let spmResourcesBundle = Bundle.module
    #endif
    public static let resourcesBundle = StripeUICoreBundleLocator.computeResourcesBundle()
}
