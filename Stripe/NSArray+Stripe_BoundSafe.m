//
//  NSArray+Stripe_BoundSafe.m
//  Stripe
//
//  Created by Jack Flintermann on 1/19/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import "NSArray+Stripe_BoundSafe.h"

@implementation NSArray (Stripe_BoundSafe)

- (nullable id)stp_boundSafeObjectAtIndex:(NSUInteger)index {
    if (index + 1 > self.count) {
        return nil;
    }
    return [self objectAtIndex:index];
}

@end
