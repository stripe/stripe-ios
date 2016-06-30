//
//  STPPostalCodeValidator.m
//  Stripe
//
//  Created by Ben Guo on 4/14/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import "STPPostalCodeValidator.h"
#import "STPCardValidator.h"
#import "STPPhoneNumberValidator.h"

@implementation STPPostalCodeValidator

+ (BOOL)stringIsValidPostalCode:(nullable NSString *)string {
    if ([STPPhoneNumberValidator isUSLocale]) {
        NSUInteger length = [STPCardValidator sanitizedNumericStringForString:string].length;
        return length > 0;
    } else {
        return string.length > 0;
    }
}

@end
