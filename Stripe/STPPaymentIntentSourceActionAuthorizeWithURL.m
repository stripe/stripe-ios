//
//  STPPaymentIntentSourceActionAuthorizeWithURL.m
//  Stripe
//
//  Created by Daniel Jackson on 11/7/18.
//  Copyright © 2018 Stripe, Inc. All rights reserved.
//

#import "STPPaymentIntentSourceActionAuthorizeWithURL.h"

@implementation STPPaymentIntentSourceActionAuthorizeWithURL

@synthesize allResponseFields;

+ (nullable instancetype)decodedObjectFromAPIResponse:(nullable NSDictionary *)response {
    // TODO
    NSLog(@"%@", response);
    return nil;
}

@end
