//
//  PKZip.m
//  PKPayment Example
//
//  Created by Alex MacCaw on 2/1/13.
//  Copyright (c) 2013 Stripe. All rights reserved.
//

#import "PKAddressZip.h"

@implementation PKAddressZip

+ (id)addressZipWithString:(NSString *)string
{
    return [[self alloc] initWithString:string];
}

- (id)initWithString:(NSString *)string
{
    self = [super init];
    if (self) {
        zip = string;
    }
    return self;
}

- (NSString *)string
{
    return zip;
}

- (BOOL) isValid
{
    NSString* stripped = [zip stringByReplacingOccurrencesOfString:@"\\s"
                                            withString:@""
                                               options:NSRegularExpressionSearch
                                                 range:NSMakeRange(0, zip.length)];

    return stripped.length > 2;
}

- (BOOL)isPartiallyValid
{
    return zip.length < 10;
}

@end
