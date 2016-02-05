//
//  NSDictionary+Stripe.m
//  Stripe
//
//  Created by Jack Flintermann on 10/15/15.
//  Copyright © 2015 Stripe, Inc. All rights reserved.
//

#import "NSDictionary+Stripe.h"

@implementation NSDictionary (Stripe)

- (nullable NSDictionary *)stp_dictionaryByRemovingNullsValidatingRequiredFields:(nonnull NSArray *)requiredFields {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [self enumerateKeysAndObjectsUsingBlock:^(id key, id obj, __unused BOOL *stop) {
        if (obj != [NSNull null]) {
            dict[key] = obj;
        }
    }];
    for (NSString *key in requiredFields) {
        if (![[dict allKeys] containsObject:key]) {
            return nil;
        }
    }
    return [dict copy];
}

- (nonnull NSDictionary *)stp_dictionaryByRemovingKeys:(nonnull NSArray *)keys {
    NSMutableDictionary *mutable = [self mutableCopy];
    [mutable removeObjectsForKeys:keys];
    return [mutable copy];
}

@end

void linkDictionaryCategory(void){}
