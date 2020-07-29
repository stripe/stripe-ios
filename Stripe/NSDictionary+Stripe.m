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

- (NSDictionary *)stp_dictionaryByRemovingNulls {
    NSMutableDictionary *result = [[NSMutableDictionary alloc] init];

    [self enumerateKeysAndObjectsUsingBlock:^(id key, id obj, __unused BOOL *stop) {
        if ([obj isKindOfClass:[NSArray class]]) {
            // Save array after removing any null values
            result[key] = [(NSArray *)obj stp_arrayByRemovingNulls];
        } else if ([obj isKindOfClass:[NSDictionary class]]) {
            // Save dictionary after removing any null values
            result[key] = [(NSDictionary *)obj stp_dictionaryByRemovingNulls];
        } else if ([obj isKindOfClass:[NSNull class]]) {
            // Skip null value
        } else {
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

#pragma mark - Getters

- (nullable NSArray *)stp_arrayForKey:(NSString *)key {
    id value = self[key];
    if (value && [value isKindOfClass:[NSArray class]]) {
        return value;
    }
    return nil;
}

- (nullable NSArray *)stp_arrayForKey:(NSString *)key withObjectType:(Class)objectType {
    id value = self[key];
    if (value && [value isKindOfClass:[NSArray class]]) {
        for (id obj in value) {
            if (![obj isKindOfClass:objectType]) {
                return nil;
            }
        }
        return value;
    }
    return nil;
}

- (BOOL)stp_boolForKey:(NSString *)key or:(BOOL)defaultValue {
    id value = self[key];
    if (value) {
        if ([value isKindOfClass:[NSNumber class]]) {
            return [value boolValue];
        }
        if ([value isKindOfClass:[NSString class]]) {
            NSString *string = [(NSString *)value lowercaseString];
            // boolValue on NSString is true for "Y", "y", "T", "t", or 1-9
            if ([string isEqualToString:@"true"] || [string boolValue]) {
                return YES;
            } else {
                return NO;
            }
        }
    }
    return defaultValue;
}

- (nullable NSDate *)stp_dateForKey:(NSString *)key {
    id value = self[key];
    if (value &&
        ([value isKindOfClass:[NSNumber class]] || [value isKindOfClass:[NSString class]])) {
        double timeInterval = [value doubleValue];
        return [NSDate dateWithTimeIntervalSince1970:timeInterval];
    }
    return nil;
}

- (nullable NSDictionary *)stp_dictionaryForKey:(NSString *)key {
    id value = self[key];
    if (value && [value isKindOfClass:[NSDictionary class]]) {
        return value;
    }
    return nil;
}

- (NSInteger)stp_intForKey:(NSString *)key or:(NSInteger)defaultValue {
    id value = self[key];
    if (value &&
        ([value isKindOfClass:[NSNumber class]] || [value isKindOfClass:[NSString class]])) {
        return [value integerValue];
    }
    return defaultValue;
}

- (nullable NSDictionary *)stp_numberForKey:(NSString *)key {
    id value = self[key];
    if (value && [value isKindOfClass:[NSNumber class]]) {
        return value;
    }
    return nil;
}

- (nullable NSString *)stp_stringForKey:(NSString *)key {
    id value = self[key];
    if (value && [value isKindOfClass:[NSString class]]) {
        return value;
    }
    return nil;
}

- (nullable NSURL *)stp_urlForKey:(NSString *)key {
    id value = self[key];
    if (value && [value isKindOfClass:[NSString class]] && ((NSString *)value).length > 0) {
        return [NSURL URLWithString:value];
    }
    return nil;
}

@end
void linkNSDictionaryCategory(void){}

NS_ASSUME_NONNULL_END
