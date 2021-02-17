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
     6. recursive search (for very strange cocoapods configurations)
     **/
    
    static NSBundle *ourBundle;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
#ifdef SWIFTPM_MODULE_BUNDLE
        ourBundle = SWIFTPM_MODULE_BUNDLE;
#endif
        if (![self bundleIsValidStripeBundle:ourBundle]) {
            ourBundle = [STDSBundleLocator stdsSPMBundle];
        }

        if (![self bundleIsValidStripeBundle:ourBundle]) {
            ourBundle = [NSBundle bundleWithPath:@"Stripe.bundle"];
        }

        if (![self bundleIsValidStripeBundle:ourBundle]) {
            // This might be the same as the previous check if not using a dynamic framework
            NSString *path = [[NSBundle bundleForClass:[STDSBundleLocatorInternal class]] pathForResource:@"Stripe" ofType:@"bundle"];
            ourBundle = [NSBundle bundleWithPath:path];
        }

        if (![self bundleIsValidStripeBundle:ourBundle]) {
            // This will be the same as mainBundle if not using a dynamic framework
            ourBundle = [NSBundle bundleForClass:[STDSBundleLocatorInternal class]];
        }

        if (![self bundleIsValidStripeBundle:ourBundle]) {
            ourBundle = [NSBundle mainBundle];
        }
        
        // Once we've found Stripe.framework, seek around to find Stripe3DS2.bundle.
        // Try to find Stripe3DS2 bundle within our current bundle
        NSString *stdsBundlePath = [[ourBundle bundlePath] stringByAppendingPathComponent:@"Stripe3DS2.bundle"];
        NSBundle *stdsBundle = [NSBundle bundleWithPath:stdsBundlePath];
        if ([self bundleIsValidStripe3DS2Bundle:stdsBundle]) {
            ourBundle = stdsBundle;
        }
        // If it's not there, it might be a level up from us?
        // (CocoaPods arranges us this way, as an example.)
        if (![self bundleIsValidStripe3DS2Bundle:stdsBundle]) {
            NSString *stdsBundlePath = [[[ourBundle bundlePath] stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"Stripe3DS2.bundle"];
            stdsBundle = [NSBundle bundleWithPath:stdsBundlePath];
            if (stdsBundle != nil) {
                ourBundle = stdsBundle;
            }
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
        if (![self bundleIsValidStripe3DS2Bundle:ourBundle]) {
            ourBundle = [self exhaustivelySearchFor3DS2Bundle];
        }
        
        // Something has gone very wrong, and the bundle is missing. We'll do what we can.
        if (![self bundleIsValidStripe3DS2Bundle:ourBundle]) {
            ourBundle = [NSBundle mainBundle];
        }
    });
    
    return ourBundle;
}

+ (NSBundle *)exhaustivelySearchFor3DS2Bundle {
    NSString *mainBundlePath = [[NSBundle mainBundle] bundlePath];
    NSDirectoryEnumerator *enumerator = [[NSFileManager defaultManager] enumeratorAtPath:mainBundlePath];
    
    for (NSString *path in enumerator) {
        if ([[path lastPathComponent] isEqualToString:@"stripe3ds2_bundle.json"]) {
            NSString *bundlePath = [mainBundlePath stringByAppendingPathComponent:[path stringByDeletingLastPathComponent]];
            return [NSBundle bundleWithPath:bundlePath];
        }
    }
    
    // We don't have a valid bundle.
    return nil;
}

+ (BOOL)bundleIsValidStripeBundle:(NSBundle *)bundle {
    if (bundle == nil) {
        return NO;
    }
    return ([bundle pathForResource:@"stripe_bundle" ofType:@"json"] != nil);
}

+ (BOOL)bundleIsValidStripe3DS2Bundle:(NSBundle *)bundle {
    if (bundle == nil) {
        return NO;
    }
    return ([bundle pathForResource:@"stripe3ds2_bundle" ofType:@"json"] != nil);
}

@end
