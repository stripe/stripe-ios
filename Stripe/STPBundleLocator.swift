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
  /// 6. recursive search (for very strange cocoapods configurations)
  ///

  static var stripeResourcesBundle: Bundle = {
    var ourBundle: Bundle?
    #if SWIFT_PACKAGE
      ourBundle = Bundle.module
    #endif

    if !isValidStripeBundle(bundle: ourBundle) {
      ourBundle = Bundle(path: "Stripe.bundle")
    }

    if !isValidStripeBundle(bundle: ourBundle) {
      // This might be the same as the previous check if not using a dynamic framework
      if let path = Bundle(for: STPBundleLocatorInternal.self).path(
        forResource: "Stripe", ofType: "bundle")
      {
        ourBundle = Bundle(path: path)
      }
    }

    if !isValidStripeBundle(bundle: ourBundle) {
      // This will be the same as mainBundle if not using a dynamic framework
      ourBundle = Bundle(for: STPBundleLocatorInternal.self)
    }

    // If we *still* haven't found it, it might be elsewhere in the application.
    //
    // As an example, Cocoapods has a "scope_if_necessary" function, which will
    // rename a bundle to disambiguate it from other identically named bundles
    // (so we might end up with "Stripe-Swift51.bundle" and "Stripe-Swift52.bundle",
    // or "Stripe-Framework.bundle" and "Stripe-Library.bundle".
    //
    // At this point, we should give up and do an exhaustive search.
    // We've included a probe file ("stripe3ds2_bundle.json") in the bundle,
    // and we'll recurse until we find it.
    if !isValidStripeBundle(bundle: ourBundle) {
      ourBundle = exhaustivelySearchForBundle()
    }
    
    if let ourBundle = ourBundle {
      return ourBundle
    } else {
      return Bundle.main
    }
  }()
    
  private static func exhaustivelySearchForBundle() -> Bundle? {
    let mainBundleURL = Bundle.main.bundleURL
    
    guard let enumerator = FileManager.default.enumerator(at: mainBundleURL, includingPropertiesForKeys: nil) else {
      return nil
    }
    
    while let url = enumerator.nextObject() as? URL {
      if url.lastPathComponent == "stripe_bundle.json" {
        let bundleURL = url.deletingLastPathComponent()
        print("\(bundleURL)")
        return Bundle.init(url: bundleURL)
      }
    }
    
    // We don't have a valid bundle.
    return nil
  }
  
  private static func isValidStripeBundle(bundle: Bundle?) -> Bool {
    guard let bundle = bundle else {
      return false
    }
    
    return (bundle.path(forResource: "stripe_bundle", ofType: "json") != nil)
  }
}

/// Using a private class to ensure that it can't be subclassed, which may
/// change the result of `bundleForClass`
class STPBundleLocatorInternal: NSObject {
}
