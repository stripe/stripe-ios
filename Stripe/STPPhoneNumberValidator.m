//
//  STPPhoneNumberValidator.m
//  Stripe
//
//  Created by Jack Flintermann on 10/16/15.
//  Copyright © 2015 Stripe, Inc. All rights reserved.
//

#import "STPPhoneNumberValidator.h"
#import "STPCardValidator.h"
#import "NSString+Stripe.h"

@implementation STPPhoneNumberValidator

+ (BOOL)stringIsValidPartialPhoneNumber:(NSString *)string {
    if (![self isUSLocale]) {
        return YES;
    }
    return [STPCardValidator sanitizedNumericStringForString:string].length <= 10;
}

+ (BOOL)stringIsValidPhoneNumber:(NSString *)string {
    if (![self isUSLocale]) {
        return YES;
    }
    return [STPCardValidator sanitizedNumericStringForString:string].length == 10;
}

+ (NSString *)formattedSanitizedPhoneNumberForString:(NSString *)string {
    NSString *sanitized = [STPCardValidator sanitizedNumericStringForString:string];
    return [self formattedPhoneNumberForString:sanitized];
}

+ (NSString *)formattedRedactedPhoneNumberForString:(NSString *)string {
    NSScanner *scanner = [NSScanner scannerWithString:string];
    NSMutableString *prefix = [NSMutableString stringWithCapacity:string.length];
    [scanner scanUpToString:@"*" intoString:&prefix];
    NSString *number = [string stringByReplacingOccurrencesOfString:prefix withString:@""];
    number = [number stringByReplacingOccurrencesOfString:@"*" withString:@"•"];
    number = [self formattedPhoneNumberForString:number];
    return [NSString stringWithFormat:@"%@ %@", prefix, number];
}

+ (NSString *)formattedPhoneNumberForString:(NSString *)string {
    if (![self isUSLocale]) {
        return string;
    }
    if (string.length >= 6) {
        return [NSString stringWithFormat:@"(%@) %@-%@",
                [string stp_safeSubstringToIndex:3],
                [[string stp_safeSubstringToIndex:6] stp_safeSubstringFromIndex:3],
                [[string stp_safeSubstringToIndex:10] stp_safeSubstringFromIndex:6]
                ];
    } else if (string.length >= 3) {
        return [NSString stringWithFormat:@"(%@) %@",
                [string stp_safeSubstringToIndex:3],
                [string stp_safeSubstringFromIndex:3]
                ];
    }
    return string;
}

+ (BOOL)isUSLocale {
    return [[[NSLocale autoupdatingCurrentLocale] localeIdentifier] isEqualToString:@"en_US"];
}

@end
