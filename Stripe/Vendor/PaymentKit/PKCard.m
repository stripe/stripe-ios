//
//  PKCard.m
//  PKPayment Example
//
//  Created by Alex MacCaw on 1/31/13.
//  Copyright (c) 2013 Stripe. All rights reserved.
//

#import "PKCard.h"

@implementation PKCard

@synthesize number, cvc, expMonth, expYear, addressZip;

- (NSString*)last4
{
    if (number.length >= 4) {
        return [number substringFromIndex:([number length] - 4)];
    } else {
        return nil;
    }
}

@end
