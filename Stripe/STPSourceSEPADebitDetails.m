//
//  STPSourceSEPADebitDetails.m
//  Stripe
//
//  Created by Brian Dorfman on 2/24/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import "STPSourceSEPADebitDetails.h"

#import "NSDictionary+Stripe.h"

@interface STPSourceSEPADebitDetails ()
@property (nonatomic, readwrite, nonnull, copy) NSDictionary *allResponseFields;
@end

@implementation STPSourceSEPADebitDetails

#pragma mark - Description

- (NSString *)description {
    NSArray *props = @[
                       // Object
                       [NSString stringWithFormat:@"%@: %p", NSStringFromClass([self class]), self],

                       // Basic SEPA debit details
                       [NSString stringWithFormat:@"last4 = %@", self.last4],

                       // Additional SEPA debit details (alphabetical)
                       [NSString stringWithFormat:@"bankCode = %@", self.bankCode],
                       [NSString stringWithFormat:@"country = %@", self.country],
                       [NSString stringWithFormat:@"fingerprint = %@", self.fingerprint],
                       [NSString stringWithFormat:@"mandateReference = %@", self.mandateReference],
                       [NSString stringWithFormat:@"mandateURL = %@", self.mandateURL],
                       ];

    return [NSString stringWithFormat:@"<%@>", [props componentsJoinedByString:@"; "]];
}

#pragma mark - STPAPIResponseDecodable

+ (instancetype)decodedObjectFromAPIResponse:(NSDictionary *)response {
    NSDictionary *dict = [response stp_dictionaryByRemovingNulls];
    if (!dict) {
        return nil;
    }
    return [[self alloc] initWithDictionary:dict];
}

- (instancetype)initWithDictionary:(NSDictionary *)dict {
    self = [super init];
    if (self) {
        _last4 = [dict stp_stringForKey:@"last4"];
        _bankCode = [dict stp_stringForKey:@"bank_code"];
        _country = [dict stp_stringForKey:@"country"];
        _fingerprint = [dict stp_stringForKey:@"fingerprint"];
        _mandateReference = [dict stp_stringForKey:@"mandate_reference"];
        _mandateURL = [dict stp_urlForKey:@"mandate_url"];

        _allResponseFields = dict.copy;
    }
    return self;
}


@end
