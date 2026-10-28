//
//  StripeUICoreBundleLocator.swift
//  StripeUICore
//
//  Created by Mel Ludowise on 9/8/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(InternalOnlyAPI) import StripeCore

@_spi(InternalOnlyAPI) public final class StripeUICoreBundleLocator: BundleLocatorProtocol {
    public static let internalClass: AnyClass = StripeUICoreBundleLocator.self
    public static let bundleName = "StripeUICoreBundle"
    #if SWIFT_PACKAGE
    public static let spmResourcesBundle = Bundle.module
    #endif
    public static let resourcesBundle = StripeUICoreBundleLocator.computeResourcesBundle()
}
