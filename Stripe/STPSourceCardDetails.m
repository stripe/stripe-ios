//
//  STPSourceCardDetails.m
//  Stripe
//
//  Created by Brian Dorfman on 2/23/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import "STPSourceCardDetails.h"
#import "STPSourceCardDetails+Private.h"

#import "STPCard+Private.h"
#import "NSDictionary+Stripe.h"

@interface STPSourceCardDetails ()

@property (nonatomic, readwrite, nonnull, copy) NSDictionary *allResponseFields;

// See STPSourceCardDetails+Private.h

@end

@implementation STPSourceCardDetails

#pragma mark - STPAPIResponseDecodable

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
        _brand = [STPCard brandFromString:dict[@"brand"]];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated"
        // This is only intended to be deprecated publicly.
        // When removed from public header, can remove these pragmas
        _funding = [STPCard fundingFromString:dict[@"funding"]];
#pragma clang diagnostic pop
        _country = dict[@"country"];
        _expMonth = [dict[@"exp_month"] intValue];
        _expYear = [dict[@"exp_year"] intValue];
        _threeDSecure = [self.class threeDSecureStatusFromString:dict[@"three_d_secure"]];
        _isApplePayCard = [dict[@"tokenization_method"] isEqual:@"apple_pay"];

        _allResponseFields = dict.copy;
    }
    return self;

}

#pragma mark - STPSourceCard3DSecureStatus

+ (NSDictionary <NSString *, NSNumber *> *)stringToThreeDSecureStatusMapping {
    return @{
             @"required": @(STPSourceCard3DSecureStatusRequired),
             @"optional": @(STPSourceCard3DSecureStatusOptional),
             @"not_supported": @(STPSourceCard3DSecureStatusNotSupported),
             };
}

+ (STPSourceCard3DSecureStatus)threeDSecureStatusFromString:(NSString *)string {
    NSString *key = [string lowercaseString];
    NSNumber *threeDSecureStatusNumber = [self stringToThreeDSecureStatusMapping][key];

    if (threeDSecureStatusNumber) {
        return (STPSourceCard3DSecureStatus)[threeDSecureStatusNumber integerValue];
    }

    return STPSourceCard3DSecureStatusUnknown;
}

+ (nullable NSString *)stringFromThreeDSecureStatus:(STPSourceCard3DSecureStatus)threeDSecureStatus {
    return [[[self stringToThreeDSecureStatusMapping] allKeysForObject:@(threeDSecureStatus)] firstObject];
}

#pragma mark - Description

- (NSString *)description {
    NSArray *props = @[
                       // Object
                       [NSString stringWithFormat:@"%@: %p", NSStringFromClass([self class]), self],

                       // Basic card details
                       [NSString stringWithFormat:@"brand = %@", [STPCard stringFromBrand:self.brand]],
                       [NSString stringWithFormat:@"last4 = %@", self.last4],
                       [NSString stringWithFormat:@"expMonth = %lu", (unsigned long)self.expMonth],
                       [NSString stringWithFormat:@"expYear = %lu", (unsigned long)self.expYear],
                       [NSString stringWithFormat:@"funding = %@", ([STPCard stringFromFunding:self.funding]) ?: @"unknown"],

                       // Additional card details (alphabetical)
                       [NSString stringWithFormat:@"country = %@", self.country],
                       [NSString stringWithFormat:@"threeDSecure = %@", ([self.class stringFromThreeDSecureStatus:self.threeDSecure]) ?: @"unknown"],
                       ];

    return [NSString stringWithFormat:@"<%@>", [props componentsJoinedByString:@"; "]];
}

@end
