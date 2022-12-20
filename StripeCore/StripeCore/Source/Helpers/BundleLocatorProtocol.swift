//
//  BundleLocatorProtocol.swift
//  StripeCore
//
//  Created by Brian Dorfman on 8/31/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

import Foundation

@_spi(STP) public protocol BundleLocatorProtocol {
    /// A final class that is internal to the bundle implementing this protocol.
    ///
    /// - Note: The class must be `final` to ensure that it can't be subclassed,
    ///   which may change the result of `bundleForClass`.
    static var internalClass: AnyClass { get }

    /// Name of the bundle.
    static var bundleName: String { get }

    /// Cached result from `computeResourcesBundle()` so it doesn't need to be recomputed.
    static var resourcesBundle: Bundle { get }

    #if SWIFT_PACKAGE
        /// SPM Bundle, if available.
        ///
        /// Implementation should be should be `Bundle.module`.
        static var spmResourcesBundle: Bundle { get }
    #endif
}

extension BundleLocatorProtocol {
    /// Computes the bundle to fetch resources from.
    ///
    /// - Note: This should never be called directly. Instead, call `resourcesBundle`.
    /// - Description:
    ///   Places to check:
    ///   1. Swift Package Manager bundle.
    ///   2. Stripe.bundle (for manual static installations and framework-less Cocoapods).
    ///   3. Stripe.framework/Stripe.bundle (for framework-based Cocoapods).
    ///   4. Stripe.framework (for Carthage, manual dynamic installations).
    ///   5. main bundle (for people dragging all our files into their project).
    public static func computeResourcesBundle() -> Bundle {
        var ourBundle: Bundle?

        #if SWIFT_PACKAGE
            ourBundle = spmResourcesBundle
        #endif

        if ourBundle == nil {
            ourBundle = Bundle(path: "\(bundleName).bundle")
        }

        if ourBundle == nil {
            // This might be the same as the previous check if not using a dynamic framework
            if let path = Bundle(for: internalClass).path(
                forResource: bundleName,
                ofType: "bundle"
            ) {
                ourBundle = Bundle(path: path)
            }
        }

        if ourBundle == nil {
            // This will be the same as mainBundle if not using a dynamic framework
            ourBundle = Bundle(for: internalClass)
        }

        if let ourBundle = ourBundle {
            return ourBundle
        } else {
            return Bundle.main
        }
    }
}
