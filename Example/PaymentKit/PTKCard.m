//
//  PTKCard.m
//  PTKPayment Example
//
//  Created by Alex MacCaw on 1/31/13.
//  Copyright (c) 2013 Stripe. All rights reserved.
//

#import "PTKCard.h"

@implementation PTKCard

- (NSString *)last4
{
    if (_number.length >= 4) {
        return [_number substringFromIndex:([_number length] - 4)];
    } else {
        return nil;
    }
}

@end
