//
//  NSDictionary+DecodingHelpers.m
//  Stripe3DS2
//
//  Created by Yuki Tokuhiro on 3/27/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

#import "NSDictionary+DecodingHelpers.h"

#import "NSError+Stripe3DS2.h"

@implementation NSDictionary (DecodingHelpers)

#pragma mark - NSArray

- (nullable NSArray *)_stds_arrayForKey:(NSString *)key arrayElementType:(Class<STDSJSONDecodable>)arrayElementType required:(BOOL)isRequired error:(NSError * _Nullable __autoreleasing * _Nullable)error {
    id value = self[key];
    
    // Missing?
    if (value == nil) {
        if (isRequired && error) {
            *error = [NSError _stds_missingJSONFieldError:key];
        }
        return nil;
    }
    
    // Invalid type or value?
    if (![value isKindOfClass:[NSArray class]]) {
        if (error) {
            *error = [NSError _stds_invalidJSONFieldError:key];
        }
        return nil;
    }
    
    NSMutableArray *returnArray = [NSMutableArray new];
    for (id json in value) {
        if (![json isKindOfClass:[NSDictionary class]]) {
            if (error) {
                *error = [NSError _stds_invalidJSONFieldError:key];
            }
            return nil;
        }
        id<STDSJSONDecodable> element = [arrayElementType decodedObjectFromJSON:json error:error];
        if (element) {
            [returnArray addObject:element];
        }
    }

    return returnArray;
}

#pragma mark - NSURL

- (nullable NSURL *)_stds_urlForKey:(NSString *)key required:(BOOL)isRequired error:(NSError * _Nullable __autoreleasing *)error {
    NSString *urlRawString = [self _stds_stringForKey:key validator:^BOOL (NSString *value) {
        return [NSURL URLWithString:value] != nil;
    } required:isRequired error:error];
    
    if (urlRawString) {
        return [NSURL URLWithString:urlRawString];
    } else {
        return nil;
    }
}

#pragma mark - NSDictionary

- (nullable NSDictionary *)_stds_dictionaryForKey:(NSString *)key required:(BOOL)isRequired error:(NSError * _Nullable __autoreleasing *)error {
    id value = self[key];
    
    // Missing?
    if (value == nil) {
        if (error && isRequired) {
            *error = [NSError _stds_missingJSONFieldError:key];
        }
        return nil;
    }
    
    // Invalid type?
    if (![value isKindOfClass:[NSDictionary class]]) {
        if (error) {
            *error = [NSError _stds_invalidJSONFieldError:key];
        }
        return nil;
    }
    
    return value;
}

#pragma mark - NSString

- (nullable NSString *)_stds_stringForKey:(NSString *)key required:(BOOL)isRequired error:(NSError * _Nullable __autoreleasing * _Nullable)error {
    return [self _stds_stringForKey:key validator:nil required:isRequired error:error];
}

- (nullable NSString *)_stds_stringForKey:(NSString *)key validator:(nullable BOOL (^)(NSString * _Nonnull))validatorBlock required:(BOOL)isRequired error:(NSError * _Nullable __autoreleasing * _Nullable)error {
    id value = self[key];

    // Missing?
    if (value == nil || ([value isKindOfClass:[NSString class]] && ((NSString *)value).length == 0)) {
        if (error) {
            if (isRequired) {
                *error = [NSError _stds_missingJSONFieldError:key];
            } else if (value != nil) {
                *error = [NSError _stds_invalidJSONFieldError:key];
            }
        }
        return nil;
    }
    
    // Invalid type or value?
    if (![value isKindOfClass:[NSString class]] || (validatorBlock && !validatorBlock(value))) {
        if (error) {
            *error = [NSError _stds_invalidJSONFieldError:key];
        }
        return nil;
    }

    return value;
}

#pragma mark - NSURL

- (NSNumber *)_stds_boolForKey:(NSString *)key required:(BOOL)isRequired error:(NSError * _Nullable __autoreleasing *)error {
    id value = self[key];
    
    // Missing?
    if (value == nil) {
        if (error && isRequired) {
            *error = [NSError _stds_missingJSONFieldError:key];
        }
        return nil;
    }
    
    // Invalid type?
    if (![value isKindOfClass:[NSNumber class]]) {
        if (error) {
            *error = [NSError _stds_invalidJSONFieldError:key];
        }
        return nil;
    }
    
    return value;
}

@end

void _stds_import_nsdictionary_decodinghelpers() {}
