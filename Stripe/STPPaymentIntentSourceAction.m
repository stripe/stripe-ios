//
//  STPPaymentIntentSourceAction.m
//  Stripe
//
//  Created by Daniel Jackson on 11/7/18.
//  Copyright © 2018 Stripe, Inc. All rights reserved.
//

#import "STPPaymentIntentSourceAction.h"

@implementation STPPaymentIntentSourceAction

@synthesize allResponseFields;

+ (nullable instancetype)decodedObjectFromAPIResponse:(nullable NSDictionary *)response {
    // TODO
    NSLog(@"%@", response);
    return nil;
}

@end
