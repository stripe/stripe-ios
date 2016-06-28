//
//  NSDecimalNumber+Stripe_Currency.m
//  Stripe
//
//  Created by Jack Flintermann on 4/20/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import "NSDecimalNumber+Stripe_Currency.h"

@implementation NSDecimalNumber (Stripe_Currency)

+ (NSDecimalNumber *)stp_decimalNumberWithAmount:(NSInteger)amount
                                        currency:(NSString *)currency {
    NSArray *noDecimalCurrencies = @[@"bif", @"clp",@"djf",@"gnf",
                                     @"jpy",@"kmf",@"krw",@"mga",@"pyg",@"rwf",@"vnd",
                                     @"vuv",@"xaf",@"xof", @"xpf"];
    NSDecimalNumber *number = [self decimalNumberWithMantissa:amount exponent:0 isNegative:NO];
    if ([noDecimalCurrencies containsObject:currency.lowercaseString]) {
        return number;
    }
    return [number decimalNumberByMultiplyingByPowerOf10:-2];
}

@end

void linkNSDecimalNumberCurrencyCategory(void){}
