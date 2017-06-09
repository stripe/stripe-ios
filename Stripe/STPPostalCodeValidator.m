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
#import "NSString+Stripe.h"

static NSString *const STPCountryCodeUnitedStates = @"US";

@implementation STPPostalCodeValidator

+ (STPCardValidationState)validationStateForPostalCode:(NSString *)postalCode
                                           countryCode:(NSString *)countryCode {
    NSString *sanitizedCountryCode = countryCode.uppercaseString;
    if ([self postalCodeIsRequiredForCountryCode:countryCode]) {
        if ([sanitizedCountryCode isEqualToString:STPCountryCodeUnitedStates]) {
            return [self validationStateForUSPostalCode:postalCode];
        }
        else {
            if (postalCode.length > 0) {
                return STPCardValidationStateValid;
            }
            else {
                return STPCardValidationStateIncomplete;
            }
        }
    }
    else {
        return STPCardValidationStateValid;
    }
}

+ (STPCardValidationState)validationStateForUSPostalCode:(NSString *)postalCode {
    NSUInteger length = postalCode.length;
    NSUInteger numberOfDigits = [STPCardValidator sanitizedNumericStringForString:postalCode].length;

    if (numberOfDigits == 5) {
        if (length == 5) {
            // Standard 5 digit zip with no extra characters
            return STPCardValidationStateValid;
        }
        else if (length == 6) {
            // Beginning of 9 digit zip (5 digits plus separator)
            // We don't currently validate which separators are allowed
            return STPCardValidationStateIncomplete;
        }
        else {
            return STPCardValidationStateInvalid;
        }
    }
    else if (numberOfDigits == 9) {
        if (length == 9 || length == 10) {
            // Standard Zip+4 with or without an extra separator character
            // (at the moment we don't validate what the separator is)
            return STPCardValidationStateValid;
        }
        else {
            return STPCardValidationStateInvalid;
        }
    }
    else if (numberOfDigits < 5) {
        if (length == numberOfDigits) {
            // On our way to a valid 5 digit
            return STPCardValidationStateIncomplete;
        }
        else {
            return STPCardValidationStateInvalid;
        }
    }
    else if (numberOfDigits < 9) {
        if (length == numberOfDigits
            || (length == numberOfDigits + 1)) {
            // On our way to a valid 9 digit
            return STPCardValidationStateIncomplete;
        }
        else {
            return STPCardValidationStateInvalid;
        }
    }
    else {
        return STPCardValidationStateInvalid;
    }
}

+ (NSString *)formattedSanitizedPostalCodeFromString:(NSString *)postalCode
                                         countryCode:(NSString *)countryCode {
    if (countryCode == nil) {
        return postalCode;
    }

    NSString *sanitizedCountryCode = countryCode.uppercaseString;
    if ([sanitizedCountryCode isEqualToString:STPCountryCodeUnitedStates]) {
        return [self formattedSanitizedUSZipCodeFromString:postalCode];
    }
    else {
        return postalCode;
    }

}

+ (NSString *)formattedSanitizedUSZipCodeFromString:(NSString *)zipCode {
    NSString *formattedString = [[STPCardValidator sanitizedNumericStringForString:zipCode] stp_safeSubstringToIndex:9];

    if (formattedString.length > 5
        || (formattedString.length == 5
            && [[zipCode substringFromIndex:(zipCode.length - 1)] isEqualToString:@"-"])) {
        NSMutableString *mutableZip = formattedString.mutableCopy;
        [mutableZip insertString:@"-" atIndex:5];
        formattedString = mutableZip.copy;
    }

    return formattedString;
}


+ (BOOL)postalCodeIsRequiredForCountryCode:(NSString *)countryCode {
    if (countryCode == nil) {
        return NO;
    }
    else {
        return (![[self countriesWithNoPostalCodes] containsObject:countryCode.uppercaseString]);
    }
}

+ (NSArray *)countriesWithNoPostalCodes {
    return @[ @"AE",
              @"AG",
              @"AN",
              @"AO",
              @"AW",
              @"BF",
              @"BI",
              @"BJ",
              @"BO",
              @"BS",
              @"BW",
              @"BZ",
              @"CD",
              @"CF",
              @"CG",
              @"CI",
              @"CK",
              @"CM",
              @"DJ",
              @"DM",
              @"ER",
              @"FJ",
              @"GD",
              @"GH",
              @"GM",
              @"GN",
              @"GQ",
              @"GY",
              @"HK",
              @"IE",
              @"JM",
              @"KE",
              @"KI",
              @"KM",
              @"KN",
              @"KP",
              @"LC",
              @"ML",
              @"MO",
              @"MR",
              @"MS",
              @"MU",
              @"MW",
              @"NR",
              @"NU",
              @"PA",
              @"QA",
              @"RW",
              @"SA",
              @"SB",
              @"SC",
              @"SL",
              @"SO",
              @"SR",
              @"ST",
              @"SY",
              @"TF",
              @"TK",
              @"TL",
              @"TO",
              @"TT",
              @"TV",
              @"TZ",
              @"UG",
              @"VU",
              @"YE",
              @"ZA",
              @"ZW"
              ];
}

@end
