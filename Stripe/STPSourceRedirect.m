//
//  STPSourceRedirect.m
//  Stripe
//
//  Created by Ben Guo on 1/25/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import "STPSourceRedirect.h"
#import "STPSourceRedirect+Private.h"

#import "NSDictionary+Stripe.h"

@interface STPSourceRedirect ()

@property (nonatomic, nullable) NSURL *returnURL;
@property (nonatomic) STPSourceRedirectStatus status;
@property (nonatomic, nullable) NSURL *url;
@property (nonatomic, readwrite, nonnull, copy) NSDictionary *allResponseFields;

@end

@implementation STPSourceRedirect

#pragma mark - STPSourceRedirectStatus

+ (NSDictionary <NSString *, NSNumber *> *)stringToStatusMapping {
    return @{
             @"pending": @(STPSourceRedirectStatusPending),
             @"succeeded": @(STPSourceRedirectStatusSucceeded),
             @"failed": @(STPSourceRedirectStatusFailed),
             @"not_required": @(STPSourceRedirectStatusNotRequired),
             };
}

+ (STPSourceRedirectStatus)statusFromString:(NSString *)string {
    NSString *key = [string lowercaseString];
    NSNumber *statusNumber = [self stringToStatusMapping][key];

    if (statusNumber != nil) {
        return (STPSourceRedirectStatus)[statusNumber integerValue];
    }

    return STPSourceRedirectStatusUnknown;
}

+ (nullable NSString *)stringFromStatus:(STPSourceRedirectStatus)status {
    return [[[self stringToStatusMapping] allKeysForObject:@(status)] firstObject];
}

#pragma mark - Description

- (NSString *)description {
    NSArray *props = @[
                       // Object
                       [NSString stringWithFormat:@"%@: %p", NSStringFromClass([self class]), self],

                       // Details (alphabetical)
                       [NSString stringWithFormat:@"returnURL = %@", self.returnURL],
                       [NSString stringWithFormat:@"status = %@", ([self.class stringFromStatus:self.status]) ?: @"unknown"],
                       [NSString stringWithFormat:@"url = %@", self.url],
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
    NSURL *returnURL = [dict stp_urlForKey:@"return_url"];
    NSString *rawStatus = [dict stp_stringForKey:@"status"];
    NSURL *url = [dict stp_urlForKey:@"url"];
    if (!returnURL || !rawStatus || !url) {
        return nil;
    }

    STPSourceRedirect *redirect = [self new];
    redirect.allResponseFields = dict;
    redirect.returnURL = returnURL;
    redirect.status = [self statusFromString:rawStatus];
    redirect.url = url;
    return redirect;
}

@end
