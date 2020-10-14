//
//  STPPaymentMethodOXXO.m
//  StripeiOS
//
//  Created by Polo Li on 6/15/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

#import "STPPaymentMethodOXXO.h"

#import "NSDictionary+Stripe.h"

NS_ASSUME_NONNULL_BEGIN

@implementation STPPaymentMethodOXXO

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
