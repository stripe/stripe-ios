//
//  STPSourceVerification.m
//  Stripe
//
//  Created by Ben Guo on 1/25/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import "STPSourceVerification.h"
#import "STPSourceVerification+Private.h"

#import "NSDictionary+Stripe.h"

@interface STPSourceVerification ()

@property (nonatomic, nullable) NSNumber *attemptsRemaining;
@property (nonatomic) STPSourceVerificationStatus status;
@property (nonatomic, readwrite, nonnull, copy) NSDictionary *allResponseFields;

@end

@implementation STPSourceVerification

#pragma mark - STPSourceVerificationStatus

+ (NSDictionary <NSString *, NSNumber *> *)stringToStatusMapping {
    return @{
             @"pending": @(STPSourceVerificationStatusPending),
             @"succeeded": @(STPSourceVerificationStatusSucceeded),
             @"failed": @(STPSourceVerificationStatusFailed),
             };
}

+ (STPSourceVerificationStatus)statusFromString:(NSString *)string {
    NSString *key = [string lowercaseString];
    NSNumber *statusNumber = [self stringToStatusMapping][key];

    if (statusNumber != nil) {
        return (STPSourceVerificationStatus)[statusNumber integerValue];
    }

    return STPSourceVerificationStatusUnknown;
}

+ (nullable NSString *)stringFromStatus:(STPSourceVerificationStatus)status {
    return [[[self stringToStatusMapping] allKeysForObject:@(status)] firstObject];
}

#pragma mark - Description

- (NSString *)description {
    NSArray *props = @[
                       // Object
                       [NSString stringWithFormat:@"%@: %p", NSStringFromClass([self class]), self],

                       // Details (alphabetical)
                       [NSString stringWithFormat:@"attemptsRemaining = %@", self.attemptsRemaining],
                       [NSString stringWithFormat:@"status = %@", ([self.class stringFromStatus:self.status]) ?: @"unknown"],
                       ];

    return [NSString stringWithFormat:@"<%@>", [props componentsJoinedByString:@"; "]];
}

#pragma mark - STPAPIResponseDecodable

+ (instancetype)decodedObjectFromAPIResponse:(NSDictionary *)response {
    NSDictionary *dict = [response stp_dictionaryByRemovingNulls];
    if (!dict) {
        return nil;
    }

    // required fields
    NSString *rawStatus = [dict stp_stringForKey:@"status"];
    if (!rawStatus) {
        return nil;
    }

    STPSourceVerification *verification = [self new];
    verification.attemptsRemaining = [dict stp_numberForKey:@"attempts_remaining"];
    verification.status = [self statusFromString:rawStatus];
    verification.allResponseFields = dict;
    return verification;
}

@end
