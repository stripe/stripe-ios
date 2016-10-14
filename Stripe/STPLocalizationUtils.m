//
//  STPLocalizationUtils.m
//  Stripe
//
//  Created by Brian Dorfman on 8/11/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import "STPLocalizationUtils.h"
#import "STPBundleLocator.h"

@implementation STPLocalizationUtils

#if DEBUG

static NSString *gLanguageOverride = nil;

+ (void)overrideLanguageTo:(NSString *)string {
    gLanguageOverride = string;
}

#endif

+ (NSString *)localizedStripeStringForKey:(NSString *)key {
    NSBundle *bundle = [STPBundleLocator stripeResourcesBundle];
    
#if DEBUG
    if (gLanguageOverride) {
        
        NSString *lprojPath = [bundle pathForResource:gLanguageOverride ofType:@"lproj"];
        if (lprojPath) {
            bundle = [NSBundle bundleWithPath:lprojPath];
        }
        [bundle localizedStringForKey:key value:nil table:nil];
    }
#endif
    
    return [bundle localizedStringForKey:key value:nil table:nil];
}

@end
