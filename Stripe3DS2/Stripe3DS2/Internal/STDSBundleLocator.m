//
//  STDSBundleLocator.m
//  Stripe3DS2
//
//  Created by David Estes on 7/23/19.
//  Copyright © 2019 Stripe. All rights reserved.
//  Based on STPBundleLocator.m in Stripe.framework
//

#import "STDSBundleLocator.h"

/**
 Using a private class to ensure that it can't be subclassed, which may
 change the result of `bundleForClass`
 */
@interface STDSBundleLocatorInternal : NSObject
@end
@implementation STDSBundleLocatorInternal
@end

@implementation STDSBundleLocator

// This is copied from SPM's resource_bundle_accessor.m
+ (NSBundle *)stdsSPMBundle {
    NSString *bundleName = @"Stripe_Stripe";

    NSArray<NSURL*> *candidates = @[
        NSBundle.mainBundle.resourceURL,
        [NSBundle bundleForClass:[self class]].resourceURL,
        NSBundle.mainBundle.bundleURL
    ];

    for (NSURL* candiate in candidates) {
        NSURL *bundlePath = [candiate URLByAppendingPathComponent:[NSString stringWithFormat:@"%@.bundle", bundleName]];

        NSBundle *bundle = [NSBundle bundleWithURL:bundlePath];
        if (bundle != nil) {
            return bundle;
        }
    }
    
    return nil;
}

+ (NSBundle *)stdsResourcesBundle {
    /**
     First, find Stripe.framework.
     Places to check:
     1. Stripe_Stripe3DS2.bundle (for SwiftPM)
     1. Stripe_Stripe.bundle (for SwiftPM)
     2. Stripe.bundle (for manual static installations, Fabric, and framework-less Cocoapods)
     3. Stripe.framework/Stripe.bundle (for framework-based Cocoapods)
     4. Stripe.framework (for Carthage, manual dynamic installations)
     5. main bundle (for people dragging all our files into their project)
     **/
    
    static NSBundle *ourBundle;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
#ifdef SWIFTPM_MODULE_BUNDLE
        ourBundle = SWIFTPM_MODULE_BUNDLE;
#endif
      
        if (ourBundle == nil) {
            ourBundle = [STDSBundleLocator stdsSPMBundle];
        }

        if (ourBundle == nil) {
            ourBundle = [NSBundle bundleWithPath:@"Stripe.bundle"];
        }

        if (ourBundle == nil) {
            // This might be the same as the previous check if not using a dynamic framework
            NSString *path = [[NSBundle bundleForClass:[STDSBundleLocatorInternal class]] pathForResource:@"Stripe" ofType:@"bundle"];
            ourBundle = [NSBundle bundleWithPath:path];
        }

        if (ourBundle == nil) {
            // This will be the same as mainBundle if not using a dynamic framework
            ourBundle = [NSBundle bundleForClass:[STDSBundleLocatorInternal class]];
        }

        if (ourBundle == nil) {
            ourBundle = [NSBundle mainBundle];
        }
        
        // Once we've found Stripe.framework, seek around to find Stripe3DS2.bundle.
        // Try to find Stripe3DS2 bundle within our current bundle
        NSString *stdsBundlePath = [[ourBundle bundlePath] stringByAppendingPathComponent:@"Stripe3DS2.bundle"];
        NSBundle *stdsBundle = [NSBundle bundleWithPath:stdsBundlePath];
        if (stdsBundle != nil) {
            ourBundle = stdsBundle;
        }
        // If it's not there, it might be a level up from us?
        // (CocoaPods arranges us this way, as an example.)
        if (stdsBundle == nil) {
            NSString *stdsBundlePath = [[[ourBundle bundlePath] stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"Stripe3DS2.bundle"];
            stdsBundle = [NSBundle bundleWithPath:stdsBundlePath];
            if (stdsBundle != nil) {
                ourBundle = stdsBundle;
            }
        }
    });
    
    return ourBundle;
}

@end
