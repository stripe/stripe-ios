//
//  STPGenericStripeObject.m
//  Stripe
//
//  Created by Daniel Jackson on 7/11/18.
//  Copyright © 2018 Stripe, Inc. All rights reserved.
//

#import "STPGenericStripeObject.h"

#import "NSDictionary+Stripe.h"

@interface STPGenericStripeObject ()
@property (nonatomic, copy, readwrite) NSString *stripeId;
@property (nonatomic, copy, readwrite) NSDictionary *allResponseFields;
@end

@implementation STPGenericStripeObject

+ (nullable instancetype)decodedObjectFromAPIResponse:(nullable NSDictionary *)response {
    NSDictionary *dict = [response stp_dictionaryByRemovingNulls];
    NSString *stripeId = [dict stp_stringForKey:@"id"];

    // required fields
    if (!stripeId) {
        return nil;
    }
    STPGenericStripeObject *source = [self new];

    source.stripeId = response[@"id"];
    source.allResponseFields = dict;

    return source;
}

@end
