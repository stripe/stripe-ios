//
//  STPPaymentMethodThreeDSecureUsage.m
//  Stripe
//
//  Created by Yuki Tokuhiro on 3/5/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import "STPPaymentMethodThreeDSecureUsage.h"

#import "NSDictionary+Stripe.h"

@interface STPPaymentMethodThreeDSecureUsage ()

@property (nonatomic, readwrite) BOOL supported;
@property (nonatomic, copy, nonnull, readwrite) NSDictionary *allResponseFields;

@end

@implementation STPPaymentMethodThreeDSecureUsage

- (NSString *)description {
    NSArray *props = @[
                       // Object
                       [NSString stringWithFormat:@"%@: %p", NSStringFromClass([self class]), self],
                       
                       // Properties
                       [NSString stringWithFormat:@"supported: %@", self.supported ? @"YES" : @"NO"]
                       ];
    
    return [NSString stringWithFormat:@"<%@>", [props componentsJoinedByString:@"; "]];
}

#pragma mark - STPAPIResponseDecodable

+ (nullable instancetype)decodedObjectFromAPIResponse:(nullable NSDictionary *)response {
    NSDictionary *dict = [response stp_dictionaryByRemovingNulls];
    if (!dict || dict[@"supported"] == nil) {
        return nil;
    }
    STPPaymentMethodThreeDSecureUsage *usage = [self new];
    usage.allResponseFields = dict;
    usage.supported = [dict stp_boolForKey:@"supported" or:NO];
    return usage;
}

@end
