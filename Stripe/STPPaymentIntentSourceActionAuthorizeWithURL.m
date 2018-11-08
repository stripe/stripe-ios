//
//  STPPaymentIntentSourceActionAuthorizeWithURL.m
//  Stripe
//
//  Created by Daniel Jackson on 11/7/18.
//  Copyright © 2018 Stripe, Inc. All rights reserved.
//

#import "STPPaymentIntentSourceActionAuthorizeWithURL.h"

#import "NSDictionary+Stripe.h"

@interface STPPaymentIntentSourceActionAuthorizeWithURL()
@property (nonatomic, strong, nonnull, readwrite) NSURL *url;
@property (nonatomic, strong, nullable, readwrite) NSURL *returnURL;
@property (nonatomic, readwrite, nonnull, copy) NSDictionary *allResponseFields;
@end

@implementation STPPaymentIntentSourceActionAuthorizeWithURL

@synthesize allResponseFields;

- (NSString *)description {
    NSArray *props = @[
                       // Object
                       [NSString stringWithFormat:@"%@: %p", NSStringFromClass([self class]), self],

                       // AuthorizeWithURL details (alphabetical)
                       [NSString stringWithFormat:@"returnURL = %@", self.returnURL],
                       [NSString stringWithFormat:@"url = %@", self.url],
                       ];

    return [NSString stringWithFormat:@"<%@>", [props componentsJoinedByString:@"; "]];
}

+ (nullable instancetype)decodedObjectFromAPIResponse:(nullable NSDictionary *)response {
    NSDictionary *dict = [response stp_dictionaryByRemovingNulls];
    if (!dict) {
        return nil;
    }

    // required fields
    NSURL *url = [dict stp_urlForKey:@"url"];
    if (!url) {
        return nil;
    }

    STPPaymentIntentSourceActionAuthorizeWithURL *authorize = [self new];

    authorize.url = url;
    authorize.returnURL = [dict stp_urlForKey:@"return_url"];
    authorize.allResponseFields = dict;

    return authorize;
}

@end
