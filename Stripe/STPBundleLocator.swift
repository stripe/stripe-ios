//
//  STPBundleLocator.swift
//  Stripe
//
//  Created by Brian Dorfman on 8/31/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

import Foundation

class STPBundleLocator: NSObject {
    /// Places to check:
    /// 1. Swift Package Manager bundle
    /// 2. Stripe.bundle (for manual static installations and framework-less Cocoapods)
    /// 3. Stripe.framework/Stripe.bundle (for framework-based Cocoapods)
    /// 4. Stripe.framework (for Carthage, manual dynamic installations)
    /// 5. main bundle (for people dragging all our files into their project)
    ///

    static var stripeResourcesBundle: Bundle = {
        var ourBundle: Bundle?
        #if SWIFT_PACKAGE
            ourBundle = Bundle.module
        #endif

        if ourBundle == nil {
            ourBundle = Bundle(path: "Stripe.bundle")
        }

        if ourBundle == nil {
            // This might be the same as the previous check if not using a dynamic framework
            if let path = Bundle(for: STPBundleLocatorInternal.self).path(
                forResource: "Stripe", ofType: "bundle")
            {
                ourBundle = Bundle(path: path)
            }
        }

        if ourBundle == nil {
            // This will be the same as mainBundle if not using a dynamic framework
            ourBundle = Bundle(for: STPBundleLocatorInternal.self)
        }

        if let ourBundle = ourBundle {
            return ourBundle
        } else {
            return Bundle.main
        }
    }()
}

/// Using a private class to ensure that it can't be subclassed, which may
/// change the result of `bundleForClass`
class STPBundleLocatorInternal: NSObject {
}
