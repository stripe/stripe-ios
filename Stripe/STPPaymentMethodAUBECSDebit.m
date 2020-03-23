//
//  STPPaymentMethodAUBECSDebit.m
//  StripeiOS
//
//  Created by Cameron Sabol on 3/3/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

#import "STPPaymentMethodAUBECSDebit.h"

#import "NSDictionary+Stripe.h"

NS_ASSUME_NONNULL_BEGIN

@implementation STPPaymentMethodAUBECSDebit

@synthesize allResponseFields = _allResponseFields;

#pragma mark - Description

- (NSString *)description {
    NSArray *props = @[
                       // Object
                       [NSString stringWithFormat:@"%@: %p", NSStringFromClass([self class]), self],

                       // AU BECS Debit details
                       [NSString stringWithFormat:@"bsbNumber = %@", self.bsbNumber],
                       [NSString stringWithFormat:@"fingerprint = %@", self.fingerprint],
                       [NSString stringWithFormat:@"last4 = %@", self.last4],
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
        _bsbNumber = [[dict stp_stringForKey:@"bsb_number"] copy];
        _fingerprint = [[dict stp_stringForKey:@"fingerprint"] copy];
        _last4 = [[dict stp_stringForKey:@"last4"] copy];

        if (_bsbNumber == nil ||
            _fingerprint == nil ||
            _last4 == nil) {
            return nil;
        }

        _allResponseFields = dict.copy;
    }
    return self;
}

@end

NS_ASSUME_NONNULL_END
