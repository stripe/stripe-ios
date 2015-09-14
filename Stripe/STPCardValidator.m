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
    return [components componentsJoinedByString:@""] ?: @"";
}

+ (NSString *)stringByRemovingSpacesFromString:(NSString *)string {
    NSCharacterSet *set = [NSCharacterSet whitespaceCharacterSet];
    NSArray *components = [string componentsSeparatedByCharactersInSet:set];
    return [components componentsJoinedByString:@""];
}

+ (BOOL)stringIsNumeric:(NSString *)string {
    return [[self sanitizedNumericStringForString:string] isEqualToString:string];
}

+ (STPCardValidationState)validationStateForExpirationMonth:(NSString *)expirationMonth {

    NSString *sanitizedExpiration = [self stringByRemovingSpacesFromString:expirationMonth];
    
    if (![self stringIsNumeric:sanitizedExpiration]) {
        return STPCardValidationStateInvalid;
    }
    
    switch (sanitizedExpiration.length) {
        case 0:
            return STPCardValidationStateIncomplete;
        case 1:
            return ([sanitizedExpiration isEqualToString:@"0"] || [sanitizedExpiration isEqualToString:@"1"]) ? STPCardValidationStateIncomplete : STPCardValidationStateValid;
        case 2:
            return (0 < sanitizedExpiration.integerValue && sanitizedExpiration.integerValue <= 12) ? STPCardValidationStateValid : STPCardValidationStateInvalid;
        default:
            return STPCardValidationStateInvalid;
    }
}

+ (STPCardValidationState)validationStateForExpirationYear:(NSString *)expirationYear inMonth:(NSString *)expirationMonth inCurrentYear:(NSInteger)currentYear currentMonth:(NSInteger)currentMonth {
    
    NSInteger moddedYear = currentYear % 100;
    
    if (![self stringIsNumeric:expirationMonth] || ![self stringIsNumeric:expirationYear]) {
        return STPCardValidationStateInvalid;
    }
    
    NSString *sanitizedMonth = [self sanitizedNumericStringForString:expirationMonth];
    NSString *sanitizedYear = [self sanitizedNumericStringForString:expirationYear];
    
    switch (sanitizedYear.length) {
        case 0:
        case 1:
            return STPCardValidationStateIncomplete;
        case 2: {
            if (sanitizedYear.integerValue == moddedYear) {
                return sanitizedMonth.integerValue >= currentMonth ? STPCardValidationStateValid : STPCardValidationStateInvalid;
            } else {
                return sanitizedYear.integerValue > moddedYear ? STPCardValidationStateValid : STPCardValidationStateInvalid;
            }
        }
        default:
            return STPCardValidationStateInvalid;
    }
}


+ (STPCardValidationState)validationStateForExpirationYear:(NSString *)expirationYear
                                                   inMonth:(NSString *)expirationMonth {
    
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSDateComponents *dateComponents = [calendar components:NSCalendarUnitYear | NSCalendarUnitMonth fromDate:[NSDate date]];
    NSInteger currentYear = dateComponents.year % 100;
    NSInteger currentMonth = dateComponents.month;
    
    return [self validationStateForExpirationYear:expirationYear inMonth:expirationMonth inCurrentYear:currentYear currentMonth:currentMonth];
}


+ (STPCardValidationState)validationStateForCVC:(NSString *)cvc cardBrand:(STPCardBrand)brand {
    
    if (![self stringIsNumeric:cvc]) {
        return STPCardValidationStateInvalid;
    }
    
    NSString *sanitizedCvc = [self sanitizedNumericStringForString:cvc];
    
    NSUInteger minLength = [self minCVCLength];
    NSUInteger maxLength = [self maxCVCLengthForCardBrand:brand];
    if (sanitizedCvc.length < minLength) {
        return STPCardValidationStateIncomplete;
    }
    else if (sanitizedCvc.length > maxLength) {
        return STPCardValidationStateInvalid;
    }
    else {
        return STPCardValidationStateValid;
    }
}

+ (STPCardValidationState)validationStateForNumber:(nonnull NSString *)cardNumber
                               validatingCardBrand:(BOOL)validatingCardBrand {
    
    NSString *sanitizedNumber = [self stringByRemovingSpacesFromString:cardNumber];
    if (![self stringIsNumeric:sanitizedNumber]) {
        return STPCardValidationStateInvalid;
    }
    
    NSArray *brands = [self possibleBrandsForNumber:sanitizedNumber];
    if (brands.count == 0 && validatingCardBrand) {
        return STPCardValidationStateInvalid;
    } else if (brands.count >= 2) {
        return STPCardValidationStateIncomplete;
    } else {
        STPCardBrand brand = (STPCardBrand)[brands.firstObject integerValue];
        NSInteger desiredLength = [self lengthForCardBrand:brand];
        if ((NSInteger)sanitizedNumber.length > desiredLength) {
            return STPCardValidationStateInvalid;
        } else if ((NSInteger)sanitizedNumber.length == desiredLength) {
            return [self stringIsValidLuhn:sanitizedNumber] ? STPCardValidationStateValid : STPCardValidationStateInvalid;
        } else {
            return STPCardValidationStateIncomplete;
        }
    }
}

+ (NSUInteger)minCVCLength {
    return 3;
}

+ (NSUInteger)maxCVCLengthForCardBrand:(STPCardBrand)brand {
    switch (brand) {
        case STPCardBrandAmex:
        case STPCardBrandUnknown:
            return 4;
        default:
            return 3;
    }
}

+ (STPCardBrand)brandForNumber:(NSString *)cardNumber {
    NSString *sanitizedNumber = [self sanitizedNumericStringForString:cardNumber];
    NSArray *brands = [self possibleBrandsForNumber:sanitizedNumber];
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
            return @[@"6011", @"622", @"64", @"65"];
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
