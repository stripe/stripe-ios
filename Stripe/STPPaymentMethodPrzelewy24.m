//
//  STPPaymentMethodPrzelewy24.m
//  StripeiOS
//
//  Created by Vineet Shah on 4/23/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

#import "STPPaymentMethodPrzelewy24.h"

#import "NSDictionary+Stripe.h"

NS_ASSUME_NONNULL_BEGIN

@implementation STPPaymentMethodPrzelewy24

@synthesize allResponseFields = _allResponseFields;

#pragma mark - Description

- (NSString *)description {
    NSArray *props = @[
                       // Object
                       [NSString stringWithFormat:@"%@: %p", NSStringFromClass([self class]), self],
                       ];

    return [NSString stringWithFormat:@"<%@>", [props componentsJoinedByString:@"; "]];
}

#pragma mark - STPAPIResponseDecodable

+ (nullable instancetype)decodedObjectFromAPIResponse:(nullable NSDictionary *)response {
    NSDictionary *dict = [response stp_dictionaryByRemovingNulls];
    if (!dict) {
        return nil;
    }
    return [[self alloc] initWithDictionary:dict];
}

- (nullable instancetype)initWithDictionary:(NSDictionary *)dict {
    self = [super init];
    if (self) {
        _allResponseFields = dict.copy;
    }
    return self;
}

@end

NS_ASSUME_NONNULL_END
