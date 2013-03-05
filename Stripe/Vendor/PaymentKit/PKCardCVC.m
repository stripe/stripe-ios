//
//  PKCardCVC.m
//  PKPayment Example
//
//  Created by Alex MacCaw on 1/22/13.
//  Copyright (c) 2013 Stripe. All rights reserved.
//

#import "PKCardCVC.h"

@interface PKCardCVC () {
@private
    NSString* cvc;
}
@end

@implementation PKCardCVC

+ (id)cardCVCWithString:(NSString *)string
{
    return [[self alloc] initWithString:string];
}

- (id)initWithString:(NSString *)string
{
    self = [super init];
    if (self) {
        // Strip non-digits
        if (string) {
            cvc = [string stringByReplacingOccurrencesOfString:@"\\D"
                                                        withString:@""
                                                           options:NSRegularExpressionSearch
                                                             range:NSMakeRange(0, string.length)];
        } else {
            cvc = [NSString string];
        }
    }
    return self;
}

- (NSString *)string
{
    return cvc;
}

- (BOOL)isValid
{
    return cvc.length >= 3 && cvc.length <= 4;
}

- (BOOL)isValidWithType:(PKCardType)type {
    if (type == PKCardTypeAmex) {
        return cvc.length == 4;
    } else {
        return cvc.length == 3;
    }
}

- (BOOL)isPartiallyValid
{
    return cvc.length <= 4;
}

- (BOOL)isPartiallyValidWithType:(PKCardType)type {
    if (type == PKCardTypeAmex) {
        return cvc.length <= 4;
    } else {
        return cvc.length <= 3;
    }
}
@end
