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
#import "NSCharacterSet+Stripe.h"
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

static NSUInteger countOfCharactersFromSetInString(NSString * _Nonnull string, NSCharacterSet * _Nonnull cs) {
    NSRange range = [string rangeOfCharacterFromSet:cs];
    NSUInteger count = 0;
    if (range.location != NSNotFound) {
        NSUInteger lastPosition = NSMaxRange(range);
        count += range.length;
        while (lastPosition < string.length) {
            range = [string rangeOfCharacterFromSet:cs options:(NSStringCompareOptions)kNilOptions range:NSMakeRange(lastPosition, string.length - lastPosition)];
            if (range.location == NSNotFound) {
                break;
            }
            else {
                count += range.length;
                lastPosition = NSMaxRange(range);
            }
        }
    }

    return count;
}


+ (STPCardValidationState)validationStateForUSPostalCode:(NSString *)postalCode {
    NSString *firstFive = [postalCode stp_safeSubstringToIndex:5];
    NSUInteger firstFiveLength = firstFive.length;
    NSUInteger totalLength = postalCode.length;

    BOOL firstFiveIsNumeric = [STPCardValidator stringIsNumeric:firstFive];
    if (!firstFiveIsNumeric) {
        // Non-numbers included in first five characters
        return STPCardValidationStateInvalid;
    }
    else if (firstFiveLength < 5) {
        // Incomplete ZIP with only numbers
        return STPCardValidationStateIncomplete;
    }
    else if (totalLength == 5) {
        // Valid 5 digit zip
        return STPCardValidationStateValid;
    }
    else {
        // ZIP+4 territory
        NSUInteger numberOfDigits = countOfCharactersFromSetInString(postalCode, [NSCharacterSet stp_asciiDigitCharacterSet]);

        if (numberOfDigits > 9) {
            // Too many digits
            return STPCardValidationStateInvalid;
        }
        else if (numberOfDigits == totalLength) {
            // All numeric postal code entered
            if (numberOfDigits == 9) {
                return STPCardValidationStateValid;
            }
            else {
                return STPCardValidationStateIncomplete;
            }

        }
        else if ((numberOfDigits + 1) == totalLength) {
            // Possibly has a separator character for ZIP+4, check to see if
            // its in the right place

            NSString *separatorCharacter = [postalCode substringWithRange:NSMakeRange(5, 1)];
            if (countOfCharactersFromSetInString(separatorCharacter, [NSCharacterSet stp_asciiDigitCharacterSet]) == 0) {
                // Non-digit is in right position to be separator
                if (numberOfDigits == 9) {
                    return STPCardValidationStateValid;
                }
                else {
                    return STPCardValidationStateIncomplete;
                }
            }
            else {
                // Non-digit is in wrong position to be separator
                return STPCardValidationStateInvalid;
            }
        }
        else {
            // Not a valid zip code (too many non-numeric characters)
            return STPCardValidationStateInvalid;
        }
    }
}
+ (NSString *)formattedSanitizedPostalCodeFromString:(NSString *)postalCode
                                         countryCode:(NSString *)countryCode
                                               usage:(STPPostalCodeIntendedUsage)usage {
    if (countryCode == nil) {
        return postalCode;
    }

    NSString *sanitizedCountryCode = countryCode.uppercaseString;
    if ([sanitizedCountryCode isEqualToString:STPCountryCodeUnitedStates]) {
        return [self formattedSanitizedUSZipCodeFromString:postalCode
                                                     usage:usage];
    }
    else {
        return postalCode;
    }

}

+ (NSString *)formattedSanitizedUSZipCodeFromString:(NSString *)zipCode
                                              usage:(STPPostalCodeIntendedUsage)usage {
    NSUInteger maxLength = 0;
    switch (usage) {
        case STPPostalCodeIntendedUsageBillingAddress:
            maxLength = 5;
            break;
        case STPPostalCodeIntendedUsageShippingAddress:
            maxLength = 9;
    }


    NSString *formattedString = [[STPCardValidator sanitizedNumericStringForString:zipCode] stp_safeSubstringToIndex:maxLength];

    /* 
     If the string is >5 numbers or == 5 and the last char of the unformatted
     string was already a hyphen, insert a hyphen at position 6 for ZIP+4
     */
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
        return YES;
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
