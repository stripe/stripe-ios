//
//  NSArray+Stripe_BoundSafe.m
//  Stripe
//
//  Created by Jack Flintermann on 1/19/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import "NSArray+Stripe.h"

#import "NSDictionary+Stripe.h"

@implementation NSArray (Stripe)

- (nullable id)stp_boundSafeObjectAtIndex:(NSInteger)index {
    if (index + 1 > (NSInteger)self.count || index < 0) {
        return nil;
    }
    return self[index];
}

- (NSArray *)stp_arrayByRemovingNulls {
    NSMutableArray *result = [[NSMutableArray alloc] init];

    for (id obj in self) {
        if ([obj isKindOfClass:[NSArray class]]) {
            // Save array after removing any null values
            [result addObject:[(NSArray *)obj stp_arrayByRemovingNulls]];
        } else if ([obj isKindOfClass:[NSDictionary class]]) {
            // Save dictionary after removing any null values
            [result addObject:[(NSDictionary *)obj stp_dictionaryByRemovingNulls]];
        } else if ([obj isKindOfClass:[NSNull class]]) {
            // Skip null value
        } else {
            // Save other value
            [result addObject:obj];
        }
    }

    // Make immutable copy
    return [result copy];
}

@end

void linkNSArrayCategory(void){}
