//
//  STPPaymentMethodAlipay.m
//  StripeiOS
//
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

#import "STPPaymentMethodAlipay.h"

#import "NSDictionary+Stripe.h"

@implementation STPPaymentMethodAlipay

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

- (instancetype)initWithDictionary:(NSDictionary *)dict {
    self = [super init];
    if (self) {
        _allResponseFields = dict.copy;
    }
    return self;
}

@end
