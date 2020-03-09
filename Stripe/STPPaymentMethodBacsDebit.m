//
//  STPPaymentMethodBacsDebit.m
//  StripeiOS
//
//  Created by Yuki Tokuhiro on 1/28/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

#import "STPPaymentMethodBacsDebit.h"

#import "NSDictionary+Stripe.h"

@implementation STPPaymentMethodBacsDebit

@synthesize allResponseFields = _allResponseFields;

#pragma mark - Description

- (NSString *)description {
    NSArray *props = @[
                       // Object
                       [NSString stringWithFormat:@"%@: %p", NSStringFromClass([self class]), self],

                       [NSString stringWithFormat:@"fingerprint = %@", self.fingerprint],
                       [NSString stringWithFormat:@"last4 = %@", self.last4],
                       [NSString stringWithFormat:@"sortCode = %@", self.sortCode],
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
        _fingerprint = [[dict stp_stringForKey:@"fingerprint"] copy];
        _last4 = [[dict stp_stringForKey:@"last4"] copy];
        _sortCode = [[dict stp_stringForKey:@"sort_code"] copy];

        _allResponseFields = dict.copy;
    }
    return self;
}

@end
