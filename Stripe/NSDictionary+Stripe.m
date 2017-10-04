//
//  NSDictionary+Stripe.m
//  Stripe
//
//  Created by Jack Flintermann on 10/15/15.
//  Copyright © 2015 Stripe, Inc. All rights reserved.
//

#import "NSDictionary+Stripe.h"

#import "NSArray+Stripe.h"

NS_ASSUME_NONNULL_BEGIN

@implementation NSDictionary (Stripe)

- (nullable NSDictionary *)stp_dictionaryByRemovingNullsValidatingRequiredFields:(NSArray *)requiredFields {
    NSDictionary *result = [self stp_dictionaryByRemovingNulls];

    for (NSString *key in requiredFields) {
        if (![[result allKeys] containsObject:key]) {
            // Result missing required field
            return nil;
        }
    }

    return result;
}

- (NSDictionary *)stp_dictionaryByRemovingNulls {
    NSMutableDictionary *result = [[NSMutableDictionary alloc] init];

    [self enumerateKeysAndObjectsUsingBlock:^(id key, id obj, __unused BOOL *stop) {
        if ([obj isKindOfClass:[NSArray class]]) {
            // Save array after removing any null values
            result[key] = [(NSArray *)obj stp_arrayByRemovingNulls];
        }
        else if ([obj isKindOfClass:[NSDictionary class]]) {
            // Save dictionary after removing any null values
            result[key] = [(NSDictionary *)obj stp_dictionaryByRemovingNulls];
        }
        else if ([obj isKindOfClass:[NSNull class]]) {
            // Skip null value
        }
        else {
            // Save other value
            result[key] = obj;
        }
    }];

    // Make immutable copy
    return [result copy];
}

- (NSDictionary<NSString *, NSString *> *)stp_dictionaryByRemovingNonStrings {
    NSMutableDictionary<NSString *, NSString *> *result = [[NSMutableDictionary alloc] init];

    [self enumerateKeysAndObjectsUsingBlock:^(id key, id obj, __unused BOOL *stop) {
        if ([key isKindOfClass:[NSString class]] && [obj isKindOfClass:[NSString class]]) {
            // Save valid key/value pair
            result[key] = obj;
        }
    }];

    // Make immutable copy
    return [result copy];
}

@end

void linkNSDictionaryCategory(void){}

NS_ASSUME_NONNULL_END
