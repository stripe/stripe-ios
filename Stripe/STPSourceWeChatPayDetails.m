//
//  STPSourceWeChatPayDetails.m
//  StripeiOS
//
//  Created by Yuki Tokuhiro on 6/4/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import "STPSourceWeChatPayDetails.h"

#import "NSDictionary+Stripe.h"

@interface STPSourceWeChatPayDetails()
@property (nonatomic, copy, readwrite) NSString *weChatAppURL;
@property (nonatomic, copy, readwrite) NSDictionary *allResponseFields;
@end

@implementation STPSourceWeChatPayDetails


#pragma mark - Description

- (NSString *)description {
    NSArray *props = @[
                       [NSString stringWithFormat:@"%@: %p", NSStringFromClass([self class]), self],
                       [NSString stringWithFormat:@"weChatAppURL = %@", self.weChatAppURL],
                       ];
    
    return [NSString stringWithFormat:@"<%@>", [props componentsJoinedByString:@"; "]];
}

#pragma mark - STPAPIResponseDecodable

+ (nullable instancetype)decodedObjectFromAPIResponse:(nullable NSDictionary *)response {
    NSDictionary *dict = [response stp_dictionaryByRemovingNulls];
    if (!dict) {
        return nil;
    }
    STPSourceWeChatPayDetails *details = [[self class] new];
    details.weChatAppURL = [dict stp_stringForKey:@"ios_native_url"];
    details.allResponseFields = dict;
    return details;
}

@end
