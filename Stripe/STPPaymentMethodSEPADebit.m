//
//  STPPaymentMethodSEPADebit.m
//  StripeiOS
//
//  Created by Cameron Sabol on 10/7/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import "STPPaymentMethodSEPADebit.h"

#import "NSDictionary+Stripe.h"

NS_ASSUME_NONNULL_BEGIN

@implementation STPPaymentMethodSEPADebit

@synthesize allResponseFields = _allResponseFields;

#pragma mark - Description

- (NSString *)description {
    NSArray *props = @[
                       // Object
                       [NSString stringWithFormat:@"%@: %p", NSStringFromClass([self class]), self],

                       // Basic SEPA debit details
                       [NSString stringWithFormat:@"last4 = %@", self.last4],

                       // Additional SEPA debit details (alphabetical)
                       [NSString stringWithFormat:@"bankCode = %@", self.bankCode],
                       [NSString stringWithFormat:@"branchCode = %@", self.branchCode],
                       [NSString stringWithFormat:@"country = %@", self.country],
                       [NSString stringWithFormat:@"fingerprint = %@", self.fingerprint],
                       [NSString stringWithFormat:@"mandate = %@", self.mandate],
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
        _last4 = [[dict stp_stringForKey:@"last4"] copy];
        _bankCode = [[dict stp_stringForKey:@"bank_code"] copy];
        _branchCode = [[dict stp_stringForKey:@"branch_code"] copy];
        _country = [[dict stp_stringForKey:@"country"] copy];
        _fingerprint = [[dict stp_stringForKey:@"fingerprint"] copy];
        _mandate = [[dict stp_stringForKey:@"mandate"] copy];

        _allResponseFields = dict.copy;
    }
    return self;
}
@end

NS_ASSUME_NONNULL_END
