//
//  STPCardValidator.m
//  Stripe
//
//  Created by Jack Flintermann on 7/15/15.
//  Copyright (c) 2015 Stripe, Inc. All rights reserved.
//

#import "STPCardValidator.h"

@implementation STPCardValidator

+ (NSString *)sanitizedNumericStringForString:(NSString *)string {
    NSCharacterSet *set = [[NSCharacterSet decimalDigitCharacterSet] invertedSet];
    NSArray *components = [string componentsSeparatedByCharactersInSet:set];
    return [components componentsJoinedByString:@""];
}

+ (STPCardValidationState)validationStateForExpirationMonth:(NSString *)expirationMonth {
    expirationMonth = [self sanitizedNumericStringForString:expirationMonth];
    switch (expirationMonth.length) {
        case 0:
            return STPCardValidationStatePossible;
        case 1:
            return ([expirationMonth isEqualToString:@"0"] || [expirationMonth isEqualToString:@"1"]) ? STPCardValidationStatePossible : STPCardValidationStateValid;
        case 2:
            return (0 < expirationMonth.integerValue && expirationMonth.integerValue <= 12) ? STPCardValidationStateValid : STPCardValidationStateInvalid;
        default:
            return STPCardValidationStateInvalid;
    }
}

+ (STPCardValidationState)validationStateForExpirationYear:(NSString *)expirationYear inMonth:(NSString *)expirationMonth {
    expirationYear = [self sanitizedNumericStringForString:expirationYear];
    
    NSDateComponents *dateComponents = [[NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian] components:NSCalendarUnitYear | NSCalendarUnitMonth fromDate:[NSDate date]];
    NSInteger currentYear = dateComponents.year % 100;
    NSInteger currentMonth = dateComponents.month;
    
    switch (expirationYear.length) {
        case 0:
        case 1:
            return STPCardValidationStatePossible;
        case 2: {
            if (expirationYear.integerValue == currentYear) {
                return expirationMonth.integerValue >= currentMonth ? STPCardValidationStateValid : STPCardValidationStateInvalid;
            } else {
                return expirationYear.integerValue > currentYear ? STPCardValidationStateValid : STPCardValidationStateInvalid;
            }
        }
        default:
            return STPCardValidationStateInvalid;
    }
}


+ (STPCardValidationState)validationStateForCVC:(NSString *)cvc cardBrand:(STPCardBrand)brand {
    NSUInteger length = [self maxCvcLengthForCardBrand:brand];
    if (cvc.length > length) {
        return STPCardValidationStateInvalid;
    } else if (cvc.length == length) {
        return STPCardValidationStateValid;
    } else {
        return STPCardValidationStatePossible;
    }
}

+ (STPCardValidationState)validationStateForNumber:(NSString *)cardNumber {
    cardNumber = [self sanitizedNumericStringForString:cardNumber];
    
    NSArray *brands = [self possibleBrandsForNumber:cardNumber];
    if (brands.count == 0) {
        return STPCardValidationStateInvalid;
    } else if (brands.count >= 2) {
        return STPCardValidationStatePossible;
    } else {
        STPCardBrand brand = (STPCardBrand)[brands.firstObject integerValue];
        NSInteger desiredLength = [self lengthForCardBrand:brand];
        if ((NSInteger)cardNumber.length > desiredLength) {
            return STPCardValidationStateInvalid;
        } else if ((NSInteger)cardNumber.length == desiredLength) {
            return [self stringIsValidLuhn:cardNumber] ? STPCardValidationStateValid : STPCardValidationStateInvalid;
        } else {
            return STPCardValidationStatePossible;
        }
    }
}

+ (NSUInteger)maxCvcLengthForCardBrand:(STPCardBrand)brand {
    switch (brand) {
        case STPCardBrandAmex:
        case STPCardBrandUnknown:
            return 4;
        default:
            return 3;
    }
}

+ (STPCardBrand)brandForNumber:(NSString *)cardNumber {
    cardNumber = [self sanitizedNumericStringForString:cardNumber];
    NSArray *brands = [self possibleBrandsForNumber:cardNumber];
    if (brands.count == 1) {
        return (STPCardBrand)[brands.firstObject integerValue];
    }
    return STPCardBrandUnknown;
}

+ (NSArray *)possibleBrandsForNumber:(NSString *)cardNumber {
    NSMutableArray *possibleBrands = [@[] mutableCopy];
    for (NSNumber *brandNumber in [self allValidBrands]) {
        STPCardBrand brand = (STPCardBrand)brandNumber.integerValue;
        if ([self prefixMatches:brand digits:cardNumber]) {
            [possibleBrands addObject:@(brand)];
        }
    }
    return [possibleBrands copy];
}

+ (NSArray *)allValidBrands {
    return @[
             @(STPCardBrandAmex),
             @(STPCardBrandDinersClub),
             @(STPCardBrandDiscover),
             @(STPCardBrandJCB),
             @(STPCardBrandMasterCard),
             @(STPCardBrandVisa),
         ];
}

+ (NSInteger)lengthForCardBrand:(STPCardBrand)brand {
    switch (brand) {
        case STPCardBrandAmex:
            return 15;
        case STPCardBrandDinersClub:
            return 14;
        default:
            return 16;
    }
}

+ (NSInteger)fragmentLengthForCardBrand:(STPCardBrand)brand {
    switch (brand) {
        case STPCardBrandAmex:
            return 5;
        case STPCardBrandDinersClub:
            return 2;
        default:
            return 4;
    }
}

+ (BOOL)prefixMatches:(STPCardBrand)brand digits:(NSString *)digits {
    if (digits.length == 0) {
        return YES;
    }
    NSArray *digitPrefixes = [self validBeginningDigits:brand];
    for (NSString *digitPrefix in digitPrefixes) {
        if ((digitPrefix.length >= digits.length && [digitPrefix hasPrefix:digits]) ||
            (digits.length >= digitPrefix.length && [digits hasPrefix:digitPrefix])) {
            return YES;
        }
    }
    return NO;
}

+ (NSArray *)validBeginningDigits:(STPCardBrand)brand {
    switch (brand) {
        case STPCardBrandAmex:
            return @[@"34", @"37"];
        case STPCardBrandDinersClub:
            return @[@"30", @"36", @"38", @"39"];
        case STPCardBrandDiscover:
            return @[@"6011", @"622", @"644", @"65"];
        case STPCardBrandJCB:
            return @[@"35"];
        case STPCardBrandMasterCard:
            return @[@"50", @"51", @"52", @"53", @"54", @"55", @"56", @"57", @"58", @"59"];
        case STPCardBrandVisa:
            return @[@"40", @"41", @"42", @"43", @"44", @"45", @"46", @"47", @"48", @"49"];
        case STPCardBrandUnknown:
            return @[];
    }
}

+ (BOOL)stringIsValidLuhn:(NSString *)number {
    BOOL odd = true;
    int sum = 0;
    NSMutableArray *digits = [NSMutableArray arrayWithCapacity:number.length];
    
    for (int i = 0; i < (NSInteger)number.length; i++) {
        [digits addObject:[number substringWithRange:NSMakeRange(i, 1)]];
    }
    
    for (NSString *digitStr in [digits reverseObjectEnumerator]) {
        int digit = [digitStr intValue];
        if ((odd = !odd)) digit *= 2;
        if (digit > 9) digit -= 9;
        sum += digit;
    }
    
    return sum % 10 == 0;
}



@end
