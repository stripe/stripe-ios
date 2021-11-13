//
//  CardScan.swift
//  CardScan
//
//  Created by Jaime Park on 1/29/20.
//

import Foundation

class CSBundle {
    // If you change the bundle name make sure to set these before
    // initializing the library

    static var bundleIdentifier = "com.stripe.stripe-scan"
    static var cardScanBundle: Bundle?
    static var namedBundle = "StripeScan"
    static var namedBundleExtension = "bundle"
    
    //  for testing
    static func bundle() -> Bundle? {
        if cardScanBundle != nil {
            return cardScanBundle
        }
        
        if let bundle = Bundle(identifier: bundleIdentifier) {
            return bundle
        }
        
        // as a fall back try getting a named bundle for cases when we deploy as source
        if let bundleUrl = Bundle(for: CSBundle.self).url(forResource: namedBundle, withExtension: namedBundleExtension) {
            return Bundle(url: bundleUrl)
        }
        
        #if SWIFT_PACKAGE
        return StripeScanBundleLocator.spmResourcesBundle
        #else
        return nil
        #endif
    }
    
    static func compiledModel(forResource: String, withExtension: String) -> URL? {
        guard let bundle = bundle() else {
            return nil
        }
        
        guard let modelcUrl = bundle.url(forResource: forResource, withExtension: withExtension) else {
            print("Could not find bundle named \"\(forResource).\(withExtension)\"")
            return nil
        }
        
        return modelcUrl
    }
}
