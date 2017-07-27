//
//  NSCharacterSet+Stripe.m
//  Stripe
//
//  Created by Brian Dorfman on 6/9/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import "NSCharacterSet+Stripe.h"

@implementation NSCharacterSet (Stripe)

+ (instancetype)stp_asciiDigitCharacterSet {
    static NSCharacterSet *cs;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        cs = [self characterSetWithCharactersInString:@"0123456789"];
    });
    return cs;
}

+ (instancetype)stp_invertedAsciiDigitCharacterSet {
    static NSCharacterSet *cs;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        cs = [[self stp_asciiDigitCharacterSet] invertedSet];
    });
    return cs;
}

@end

void linkNSCharacterSetCategory(void){}
