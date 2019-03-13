//
//  STPPaymentIntentActionRedirectToURL.m
//  Stripe
//
//  Created by Yuki Tokuhiro on 3/8/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import "STPPaymentIntentActionRedirectToURL.h"

#import "NSDictionary+Stripe.h"

@interface STPPaymentIntentActionRedirectToURL()

@property (nonatomic, nonnull) NSURL *url;
@property (nonatomic, nullable) NSURL *returnURL;
@property (nonatomic, nonnull, copy) NSDictionary *allResponseFields;

@end

@implementation STPPaymentIntentActionRedirectToURL

- (NSString *)description {
    NSArray *props = @[
                       // Object
                       [NSString stringWithFormat:@"%@: %p", NSStringFromClass([self class]), self],
                       
                       // RedirectToURL details (alphabetical)
                       [NSString stringWithFormat:@"returnURL = %@", self.returnURL],
                       [NSString stringWithFormat:@"url = %@", self.url],
                       ];
    
    return [NSString stringWithFormat:@"<%@>", [props componentsJoinedByString:@"; "]];
}

#pragma mark - STPAPIResponseDecodable

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
    
    STPPaymentIntentActionRedirectToURL *redirect = [self new];
    
    redirect.url = url;
    redirect.returnURL = [dict stp_urlForKey:@"return_url"];
    redirect.allResponseFields = dict;
    
    return redirect;
}

@end
