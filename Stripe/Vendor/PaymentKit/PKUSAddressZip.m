//
//  PKUSAddressZip.m
//  PaymentKit Example
//
//  Created by Alex MacCaw on 2/17/13.
//  Copyright (c) 2013 Stripe. All rights reserved.
//

#import "PKUSAddressZip.h"

@implementation PKUSAddressZip

- (id)initWithString:(NSString *)string
{
    self = [super init];
    if (self) {
        // Strip non-digits
        zip = [string stringByReplacingOccurrencesOfString:@"\\D"
                                                withString:@""
                                                   options:NSRegularExpressionSearch
                                                     range:NSMakeRange(0, string.length)];
    }
    return self;
}

- (BOOL) isValid
{
    return zip.length == 5;
}

- (BOOL)isPartiallyValid
{
    return zip.length <= 5;
}

@end
