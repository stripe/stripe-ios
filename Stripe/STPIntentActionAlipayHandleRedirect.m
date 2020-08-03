//
//  STPIntentActionAlipayHandleRedirect.m
//  Stripe
//
//  Created by Yuki Tokuhiro on 8/3/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

#import "STPIntentActionAlipayHandleRedirect.h"

#import "NSDictionary+Stripe.h"
#import "NSURLComponents+Stripe.h"

@interface STPIntentActionAlipayHandleRedirect()

@property (nonatomic, nonnull) NSURL *nativeURL;
@property (nonatomic, nonnull) NSURL *returnURL;
@property (nonatomic, nonnull) NSURL *url;
@property (nonatomic, nonnull, copy) NSDictionary *allResponseFields;

@end

@implementation STPIntentActionAlipayHandleRedirect

#pragma mark - STPAPIResponseDecodable

- (NSString *)description {
    NSArray *props = @[
        // Object
        [NSString stringWithFormat:@"%@: %p", NSStringFromClass([self class]), self],
        
        // RedirectToURL details (alphabetical)
        [NSString stringWithFormat:@"nativeURL = %@", self.nativeURL],
        [NSString stringWithFormat:@"url = %@", self.url],
        [NSString stringWithFormat:@"returnURL = %@", self.returnURL],
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
    NSURL *nativeURL = [dict stp_urlForKey:@"native_url"];
    NSURL *returnURL = [dict stp_urlForKey:@"return_url"];
    if (!url || !returnURL) {
        return nil;
    }
    
    STPIntentActionAlipayHandleRedirect *redirect = [self new];
    
    redirect.nativeURL = nativeURL;
    redirect.url = url;
    redirect.returnURL = returnURL;
    redirect.allResponseFields = dict;

    return redirect;
}

@end
