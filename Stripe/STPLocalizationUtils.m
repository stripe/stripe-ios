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

+ (NSString *)localizedStripeStringForKey:(NSString *)key {
    return [[STPBundleLocator stripeResourcesBundle] localizedStringForKey:key value:key table:nil];
}

@end
