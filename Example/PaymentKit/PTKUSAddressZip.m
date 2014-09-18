//
//  PTKUSAddressZip.m
//  PaymentKit Example
//
//  Created by Alex MacCaw on 2/17/13.
//  Copyright (c) 2013 Stripe. All rights reserved.
//

#import "PTKUSAddressZip.h"

@implementation PTKUSAddressZip

- (id)initWithString:(NSString *)string
{
   if (self = [super init]) {
        // Strip non-digits
        _zip = [string stringByReplacingOccurrencesOfString:@"\\D"
                                                 withString:@""
                                                    options:NSRegularExpressionSearch
                                                      range:NSMakeRange(0, string.length)];
    }
    return self;
}

- (BOOL)isValid
{
    return _zip.length == 5;
}

- (BOOL)isPartiallyValid
{
    return _zip.length <= 5;
}

@end
