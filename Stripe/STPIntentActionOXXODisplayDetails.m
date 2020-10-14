//
//  STPIntentActionOXXODisplayDetails.m
//  Stripe
//
//  Created by Polo Li on 6/23/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

#import "STPIntentActionOXXODisplayDetails.h"

#import "NSDictionary+Stripe.h"
#import "NSURLComponents+Stripe.h"

@interface STPIntentActionOXXODisplayDetails()

@property (nonatomic, nonnull) NSDate *expiresAfter;
@property (nonatomic, nonnull) NSURL *hostedVoucherURL;
@property (nonatomic, nonnull) NSString *number;
@property (nonatomic, nonnull, copy) NSDictionary *allResponseFields;

@end

@implementation STPIntentActionOXXODisplayDetails

- (NSString *)description {
        NSArray *props = @[
                       // Object
                       [NSString stringWithFormat:@"%@: %p", NSStringFromClass([self class]), self],

                       // OXXODisplayDetails
                       [NSString stringWithFormat:@"expiresAfter = %@", self.expiresAfter],
                       [NSString stringWithFormat:@"hostedVoucherURL = %@", self.hostedVoucherURL],
                       [NSString stringWithFormat:@"number = %@", self.number],
                       ];

    return [NSString stringWithFormat:@"<%@>", [props componentsJoinedByString:@"; "]];
}

#pragma mark - STPAPIResponseDecodable

+ (nullable instancetype)decodedObjectFromAPIResponse:(nullable NSDictionary*)response {
    NSDictionary *dict = [response stp_dictionaryByRemovingNulls];
    if(!dict) {
        return nil;
    }

    NSDate *expiresAfter = [dict stp_dateForKey:@"expires_after"];
    NSURL *hostedVoucherURL = [dict stp_urlForKey:@"hosted_voucher_url"];
    NSString *number = [dict stp_stringForKey:@"number"];

    if(!expiresAfter || !hostedVoucherURL || !number) {
        return nil;
    }

    STPIntentActionOXXODisplayDetails *oxxoDisplayDetails = [self new];
    oxxoDisplayDetails.expiresAfter = expiresAfter;
    oxxoDisplayDetails.hostedVoucherURL = hostedVoucherURL;
    oxxoDisplayDetails.number = number;
    oxxoDisplayDetails.allResponseFields = dict;

    return oxxoDisplayDetails;
}

@end
