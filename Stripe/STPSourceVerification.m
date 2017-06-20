//
//  STPSourceVerification.m
//  Stripe
//
//  Created by Ben Guo on 1/25/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import "NSDictionary+Stripe.h"
#import "STPSourceVerification.h"

@interface STPSourceVerification ()

@property (nonatomic, nullable) NSNumber *attemptsRemaining;
@property (nonatomic) STPSourceVerificationStatus status;
@property (nonatomic, readwrite, nonnull, copy) NSDictionary *allResponseFields;

@end

@implementation STPSourceVerification

+ (STPSourceVerificationStatus)statusFromString:(NSString *)string {
    NSString *status = [string lowercaseString];
    if ([status isEqualToString:@"pending"]) {
        return STPSourceVerificationStatusPending;
    } else if ([status isEqualToString:@"succeeded"]) {
        return STPSourceVerificationStatusSucceeded;
    } else if ([status isEqualToString:@"failed"]) {
        return STPSourceVerificationStatusFailed;
    } else {
        return STPSourceVerificationStatusUnknown;
    }
}

#pragma mark - Description

- (NSString *)description {
    NSString *statusDescription;

    switch (self.status) {
        case STPSourceVerificationStatusPending:
            statusDescription = @"pending";
            break;
        case STPSourceVerificationStatusSucceeded:
            statusDescription = @"succeeded";
            break;
        case STPSourceVerificationStatusFailed:
            statusDescription = @"failed";
            break;
        case STPSourceVerificationStatusUnknown:
            statusDescription = @"unknown";
            break;
    }

    NSArray *props = @[
                       // Object
                       [NSString stringWithFormat:@"%@: %p", NSStringFromClass([self class]), self],

                       // Details (alphabetical)
                       [NSString stringWithFormat:@"attemptsRemaining = %@", self.attemptsRemaining],
                       [NSString stringWithFormat:@"status = %@", statusDescription],
                       ];

    return [NSString stringWithFormat:@"<%@>", [props componentsJoinedByString:@"; "]];
}

#pragma mark - STPAPIResponseDecodable

+ (NSArray *)requiredFields {
    return @[@"status"];
}

+ (instancetype)decodedObjectFromAPIResponse:(NSDictionary *)response {
    NSDictionary *dict = [response stp_dictionaryByRemovingNullsValidatingRequiredFields:[self requiredFields]];
    if (!dict) {
        return nil;
    }

    STPSourceVerification *verification = [self new];
    verification.allResponseFields = dict;
    verification.attemptsRemaining = dict[@"attempts_remaining"];
    verification.status = [self statusFromString:dict[@"status"]];
    return verification;
}

@end
