//
//  STPSourceCardDetails.m
//  Stripe
//
//  Created by Brian Dorfman on 2/23/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import "STPSourceCardDetails.h"

#import "NSDictionary+Stripe.h"

@interface STPSourceCardDetails ()
@property (nonatomic, readwrite, nonnull, copy) NSDictionary *allResponseFields;
@end

@implementation STPSourceCardDetails

#pragma mark STPAPIResponseDecodable
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
        NSString *brand = [dict[@"brand"] lowercaseString];
        _brand = [STPCard brandFromString:brand];
        NSString *funding = dict[@"funding"];
        _funding = [STPCard fundingFromString:funding];
        _country = dict[@"country"];
        _expMonth = [dict[@"exp_month"] intValue];
        _expYear = [dict[@"exp_year"] intValue];
        _threeDSecure = [self.class threeDSecureStatusFromString:dict[@"three_d_secure"]];

        _allResponseFields = dict.copy;
    }
    return self;

}

+ (STPSourceCard3DSecureStatus)threeDSecureStatusFromString:(NSString *)string {
    NSString *brand = [string lowercaseString];
    if ([brand isEqualToString:@"required"]) {
        return STPSourceCard3DSecureStatusRequired;
    } else if ([brand isEqualToString:@"optional"]) {
        return STPSourceCard3DSecureStatusOptional;
    } else if ([brand isEqualToString:@"not_supported"]) {
        return STPSourceCard3DSecureStatusNotSupported;
    } else {
        return STPSourceCard3DSecureStatusUnknown;
    }
}

#pragma mark - Description

- (NSString *)description {
    NSString *fundingDescription;

    switch (self.funding) {
        case STPCardFundingTypeCredit:
            fundingDescription = @"credit";
        case STPCardFundingTypeDebit:
            fundingDescription = @"debit";
        case STPCardFundingTypePrepaid:
            fundingDescription = @"prepaid";
        case STPCardFundingTypeOther:
            fundingDescription = @"other";
    }

    NSString *threeDSecureStatusDescription;

    switch (self.threeDSecure) {
        case STPSourceCard3DSecureStatusRequired:
            threeDSecureStatusDescription = @"required";
        case STPSourceCard3DSecureStatusOptional:
            threeDSecureStatusDescription = @"optional";
        case STPSourceCard3DSecureStatusNotSupported:
            threeDSecureStatusDescription = @"not_supported";
        case STPSourceCard3DSecureStatusUnknown:
            threeDSecureStatusDescription = @"unknown";
    }

    NSArray *props = @[
                       // Object
                       [NSString stringWithFormat:@"%@: %p", NSStringFromClass([self class]), self],

                       // Basic card details
                       [NSString stringWithFormat:@"brand = %@", [STPCard stringFromBrand:self.brand]],
                       [NSString stringWithFormat:@"last4 = %@", self.last4],
                       [NSString stringWithFormat:@"expMonth = %lu", (unsigned long)self.expMonth],
                       [NSString stringWithFormat:@"expYear = %lu", (unsigned long)self.expYear],
                       [NSString stringWithFormat:@"funding = %@", fundingDescription],

                       // Additional card details (alphabetical)
                       [NSString stringWithFormat:@"country = %@", self.country],
                       [NSString stringWithFormat:@"threeDSecure = %@", threeDSecureStatusDescription],
                       ];

    return [NSString stringWithFormat:@"<%@>", [props componentsJoinedByString:@"; "]];
}

@end
