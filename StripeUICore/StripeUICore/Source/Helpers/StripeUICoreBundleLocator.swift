//
//  StripeUICoreBundleLocator.swift
//  StripeUICore
//
//  Created by Mel Ludowise on 9/8/21.
//

import Foundation
@_spi(STP) import StripeCore

final class StripeUICoreBundleLocator: BundleLocatorProtocol {
    static let internalClass: AnyClass = StripeUICoreBundleLocator.self
    static let bundleName = "StripeUICore"
    #if SWIFT_PACKAGE
    static let spmResourcesBundle = Bundle.module
    #endif
    static let resourcesBundle = StripeUICoreBundleLocator.computeResourcesBundle()
}
