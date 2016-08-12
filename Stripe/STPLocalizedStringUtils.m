//
//  STPLocalizedStringUtils.m
//  Stripe
//
//  Created by Brian Dorfman on 8/11/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import "STPLocalizedStringUtils.h"

@implementation STPLocalizedStringUtils

+ (NSString *)localizedStripeStringForKey:(NSString *)key {
    NSBundle *ourBundle = [NSBundle bundleWithPath:@"Stripe.bundle"];
    
    if (ourBundle == nil) {
        ourBundle = [NSBundle bundleForClass:[self class]];
    }
    if (ourBundle == nil) {
        ourBundle = [NSBundle mainBundle];
    }
    
    return [ourBundle localizedStringForKey:key value:@"" table:nil];
}

@end
