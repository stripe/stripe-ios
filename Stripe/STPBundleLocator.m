//
//  STPBundleLocator.m
//  Stripe
//
//  Created by Brian Dorfman on 8/31/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import "STPBundleLocator.h"

/**
 Using a private class to ensure that it can't be subclassed, which may
 change the result of `bundleForClass`
 */
@interface STPBundleLocatorInternal : NSObject
@end
@implementation STPBundleLocatorInternal
@end

@implementation STPBundleLocator
+ (NSBundle *)stripeResourcesBundle {
    /**
     Places to check:
     1. Swift Package Manager bundle
     2. Stripe.bundle (for manual static installations and framework-less Cocoapods)
     3. Stripe.framework/Stripe.bundle (for framework-based Cocoapods)
     4. Stripe.framework (for Carthage, manual dynamic installations)
     5. main bundle (for people dragging all our files into their project)
     **/
    
    static NSBundle *ourBundle;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        #ifdef SWIFT_PACKAGE
        if (Stripe_Stripe_SWIFTPM_MODULE_BUNDLE()) {
            ourBundle = Stripe_Stripe_SWIFTPM_MODULE_BUNDLE();
        }
        #endif

        if (ourBundle == nil) {
            ourBundle = [NSBundle bundleWithPath:@"Stripe.bundle"];
        }
        
        if (ourBundle == nil) {
            // This might be the same as the previous check if not using a dynamic framework
            NSString *path = [[NSBundle bundleForClass:[STPBundleLocatorInternal class]] pathForResource:@"Stripe" ofType:@"bundle"];
            ourBundle = [NSBundle bundleWithPath:path];
        }
        
        if (ourBundle == nil) {
            // This will be the same as mainBundle if not using a dynamic framework
            ourBundle = [NSBundle bundleForClass:[STPBundleLocatorInternal class]];
        }
        
        if (ourBundle == nil) {
            ourBundle = [NSBundle mainBundle];
        }
    });

    return ourBundle;
}

@end
