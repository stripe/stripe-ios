//
//  STPNumericStringValidator.m
//  StripeiOS
//
//  Created by Cameron Sabol on 3/6/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

#import "STPNumericStringValidator.h"

#import "NSCharacterSet+Stripe.h"
#import "NSString+Stripe.h"

NS_ASSUME_NONNULL_BEGIN

@implementation STPNumericStringValidator

+ (BOOL)isStringNumeric:(NSString *)string {
     return [string rangeOfCharacterFromSet:[NSCharacterSet stp_invertedAsciiDigitCharacterSet]].location == NSNotFound;
}

+ (NSString *)sanitizedNumericStringForString:(NSString *)string {
    return [string stp_stringByRemovingCharactersFromSet:[NSCharacterSet stp_invertedAsciiDigitCharacterSet]];
}

@end

NS_ASSUME_NONNULL_END
