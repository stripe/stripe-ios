//
//  STPLocalizationUtils+STPTestAdditions.m
//  Stripe
//
//  Created by Brian Dorfman on 10/31/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import "STPLocalizationUtils+STPTestAdditions.h"


@implementation STPLocalizationUtils (TestAdditions)

static NSString *languageOverride = nil;

+ (void)overrideLanguageTo:(NSString *)string {
    languageOverride = string;
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-protocol-method-implementation"


/**
 Clobber the real implementation with this one that lets us change
 the lproj
 */
+ (NSString *)localizedStripeStringForKey:(NSString *)key {
    NSBundle *bundle = [STPBundleLocator stripeResourcesBundle];
    
    if (languageOverride) {
        
        NSString *lprojPath = [bundle pathForResource:languageOverride ofType:@"lproj"];
        if (lprojPath) {
            bundle = [NSBundle bundleWithPath:lprojPath];
        }
    }
    return [bundle localizedStringForKey:key value:nil table:nil];
}
#pragma clang diagnostic pop

@end
