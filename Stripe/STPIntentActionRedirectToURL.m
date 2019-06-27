//
//  STPIntentActionRedirectToURL.m
//  Stripe
//
//  Created by Yuki Tokuhiro on 6/27/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//
#import "STPIntentActionRedirectToURL.h"

#import "NSDictionary+Stripe.h"

@interface STPIntentActionRedirectToURL()

@property (nonatomic, nonnull) NSURL *url;
@property (nonatomic, nullable) NSURL *returnURL;
@property (nonatomic, nonnull, copy) NSDictionary *allResponseFields;

@end

@implementation STPIntentActionRedirectToURL

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
    
    STPIntentActionRedirectToURL *redirect = [self new];
    
    redirect.url = url;
    redirect.returnURL = [dict stp_urlForKey:@"return_url"];
    redirect.allResponseFields = dict;
    
    return redirect;
}

@end
