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

+ (NSArray *)requiredFields {
    return @[];
}

+ (instancetype)decodedObjectFromAPIResponse:(NSDictionary *)response {
    NSDictionary *dict = [response stp_dictionaryByRemovingNullsValidatingRequiredFields:[self requiredFields]];
    if (!dict) {
        return nil;
    }
    return [[self alloc] initWithDictionary:dict];
}

- (instancetype)initWithDictionary:(NSDictionary *)dict {
    self = [super init];
    if (self) {
        _last4 = dict[@"last4"];
        _bankCode = dict[@"bank_code"];
        _country = dict[@"country"];
        _fingerprint = dict[@"fingerprint"];
        _mandateReference = dict[@"mandate_reference"];
        NSString *urlString = dict[@"mandate_url"];
        if (urlString) {
            _mandateURL = [NSURL URLWithString:urlString];
        }

        _allResponseFields = dict.copy;
    }
    return self;
}


@end
