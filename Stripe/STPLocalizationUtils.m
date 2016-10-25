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

static NSString *languageOverride = nil;

+ (void)overrideLanguageTo:(NSString *)string {
    languageOverride = string;
}

#endif

+ (NSString *)localizedStripeStringForKey:(NSString *)key {
    NSBundle *bundle = [STPBundleLocator stripeResourcesBundle];
    
#if DEBUG
    if (languageOverride) {
        
        NSString *lprojPath = [bundle pathForResource:languageOverride ofType:@"lproj"];
        if (lprojPath) {
            bundle = [NSBundle bundleWithPath:lprojPath];
        }
    }
#endif
    
    return [bundle localizedStringForKey:key value:nil table:nil];
}

@end
