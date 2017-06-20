//
//  STPSourceRedirect.m
//  Stripe
//
//  Created by Ben Guo on 1/25/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import "NSDictionary+Stripe.h"
#import "STPSourceRedirect.h"

@interface STPSourceRedirect ()

@property (nonatomic, nullable) NSURL *returnURL;
@property (nonatomic) STPSourceRedirectStatus status;
@property (nonatomic, nullable) NSURL *url;
@property (nonatomic, readwrite, nonnull, copy) NSDictionary *allResponseFields;

@end

@implementation STPSourceRedirect

+ (STPSourceRedirectStatus)statusFromString:(NSString *)string {
    NSString *status = [string lowercaseString];
    if ([status isEqualToString:@"pending"]) {
        return STPSourceRedirectStatusPending;
    } else if ([status isEqualToString:@"succeeded"]) {
        return STPSourceRedirectStatusSucceeded;
    } else if ([status isEqualToString:@"failed"]) {
        return STPSourceRedirectStatusFailed;
    } else {
        return STPSourceRedirectStatusUnknown;
    }
}

#pragma mark - Description

- (NSString *)description {
    NSString *statusDescription;

    switch (self.status) {
        case STPSourceRedirectStatusPending:
            statusDescription = @"pending";
        case STPSourceRedirectStatusSucceeded:
            statusDescription = @"succeeded";
        case STPSourceRedirectStatusFailed:
            statusDescription = @"failed";
        case STPSourceRedirectStatusUnknown:
            statusDescription = @"unknown";
    }

    NSArray *props = @[
                       // Object
                       [NSString stringWithFormat:@"%@: %p", NSStringFromClass([self class]), self],

                       // Details (alphabetical)
                       [NSString stringWithFormat:@"returnURL = %@", self.returnURL],
                       [NSString stringWithFormat:@"status = %@", statusDescription],
                       [NSString stringWithFormat:@"url = %@", self.url],
                       ];

    return [NSString stringWithFormat:@"<%@>", [props componentsJoinedByString:@"; "]];
}

#pragma mark - STPAPIResponseDecodable

+ (NSArray *)requiredFields {
    return @[@"return_url", @"status", @"url"];
}

+ (instancetype)decodedObjectFromAPIResponse:(NSDictionary *)response {
    NSDictionary *dict = [response stp_dictionaryByRemovingNullsValidatingRequiredFields:[self requiredFields]];
    if (!dict) {
        return nil;
    }

    STPSourceRedirect *redirect = [self new];
    redirect.allResponseFields = dict;
    redirect.returnURL = [NSURL URLWithString:dict[@"return_url"]];
    redirect.status = [self statusFromString:dict[@"status"]];
    redirect.url = [NSURL URLWithString:dict[@"url"]];
    return redirect;
}

@end
