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

+ (NSString *)formattedPhoneNumberForString:(NSString *)string {
    NSString *sanitized = [STPCardValidator sanitizedNumericStringForString:string];
    if (![self isUSLocale]) {
        return sanitized;
    }
    if (sanitized.length >= 6) {
        return [NSString stringWithFormat:@"(%@) %@-%@",
                [sanitized stp_safeSubstringToIndex:3],
                [[sanitized stp_safeSubstringToIndex:6] stp_safeSubstringFromIndex:3],
                [[sanitized stp_safeSubstringToIndex:10] stp_safeSubstringFromIndex:6]
                ];
    } else if (sanitized.length >= 3) {
        return [NSString stringWithFormat:@"(%@) %@",
                [sanitized stp_safeSubstringToIndex:3],
                [sanitized stp_safeSubstringFromIndex:3]
                ];
    }
    return sanitized;
}

+ (BOOL)isUSLocale {
    return [[[NSLocale autoupdatingCurrentLocale] localeIdentifier] isEqualToString:@"en_US"];
}

@end
