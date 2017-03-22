//
//  STPIBANValidator.m
//  Stripe
//
//  Created by Ben Guo on 2/15/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import "STPIBANValidator.h"

#import "NSString+Stripe.h"

@interface STPParsedIBAN : NSObject
@property (nonatomic, copy) NSString *countryCode;
@property (nonatomic, copy) NSString *checkDigits;
@property (nonatomic, copy) NSString *bban;
@end

@implementation STPParsedIBAN

+ (NSCharacterSet *)invertedDigits {
    static NSCharacterSet *cs;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        cs = [[NSCharacterSet characterSetWithCharactersInString:@"0123456789"] invertedSet];
    });
    return cs;
}

+ (NSCharacterSet *)invertedLetters {
    static NSCharacterSet *cs;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        cs = [[NSCharacterSet characterSetWithCharactersInString:@"ABCDEFGHIJKLMNOPQRSTUVWXYZ"] invertedSet];
    });
    return cs;
}

+ (NSCharacterSet *)invertedDigitsAndLetters {
    static NSCharacterSet *cs;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSMutableCharacterSet *mcs = [[[self class] invertedDigits] mutableCopy];
        [mcs formIntersectionWithCharacterSet:[[self class] invertedLetters]];
        cs = [mcs copy];
    });
    return cs;
}

- (instancetype)initWithString:(NSString *)string {
    self = [super init];
    if (self) {
        NSString *sanitized = [string uppercaseString];
        NSCharacterSet *invertedDigits = [[self class] invertedDigits];
        NSCharacterSet *invertedLetters = [[self class] invertedLetters];
        NSCharacterSet *invertedDigitsAndLetters = [[self class] invertedDigitsAndLetters];
        sanitized = [sanitized stp_stringByRemovingCharactersFromSet:invertedDigitsAndLetters];
        NSString *countryCode = [sanitized stp_safeSubstringToIndex:2];
        _countryCode = [countryCode stp_stringByRemovingCharactersFromSet:invertedLetters];
        NSString *checkDigits = [sanitized stp_safeSubstringWithRange:NSMakeRange(2, 2)];
        _checkDigits = [checkDigits stp_stringByRemovingCharactersFromSet:invertedDigits];
        _bban = [sanitized stp_safeSubstringFromIndex:4];
    }
    return self;
}

@end

@implementation STPIBANValidator

/**
 Note that this only includes SEPA countries. IBANs from non-SEPA countries are 
 considered invalid.
 Source: https://bfsfcu.org/pdf/IBAN.pdf
 */
+ (NSDictionary<NSString*,NSNumber*>*)countryCodeToBBANLength {
    return @{
             @"AT": @(16),
             @"BE": @(12),
             @"BG": @(18),
             @"CH": @(17),
             @"CY": @(24),
             @"CZ": @(20),
             @"DE": @(18),
             @"DK": @(14),
             @"EE": @(16),
             @"ES": @(20),
             @"FI": @(14),
             @"FR": @(23),
             @"GB": @(18),
             @"GR": @(23),
             @"HR": @(17),
             @"HU": @(24),
             @"IE": @(18),
             @"IS": @(22),
             @"IT": @(23),
             @"LI": @(17),
             @"LV": @(17),
             @"LT": @(16),
             @"LU": @(16),
             @"MC": @(23),
             @"MT": @(27),
             @"NL": @(14),
             @"NO": @(11),
             @"PL": @(24),
             @"PT": @(21),
             @"RO": @(20),
             @"SE": @(20),
             @"SK": @(20),
             @"SI": @(15),
             @"SM": @(23),
             };
}

+ (NSString *)sanitizedIBANForString:(NSString *)string {
    STPParsedIBAN *iban = [[STPParsedIBAN alloc] initWithString:string];
    if (iban.countryCode.length < 2) {
        return iban.countryCode;
    }
    NSString *prefix = [iban.countryCode stringByAppendingString:iban.checkDigits];
    if (iban.checkDigits.length < 2) {
        return prefix;
    }
    NSNumber *length = [[self class] countryCodeToBBANLength][iban.countryCode];
    NSString *bban = iban.bban;
    if (length) {
        bban = [bban stp_safeSubstringToIndex:[length integerValue]];
    }
    return [prefix stringByAppendingString:bban];
}

+ (BOOL)stringIsValidPartialIBAN:(NSString *)string {
    if (string.length < 2) {
        return YES;
    } else {
        NSString *countryCode = [string stp_safeSubstringToIndex:2];
        return [[self class] countryCodeToBBANLength][countryCode] != nil;
    }
}

+ (NSString *)stringByReplacingLettersWithDigits:(NSString *)string {
    NSMutableString *result = [NSMutableString new];
    for (NSUInteger i = 0; i < string.length; i++) {
        NSString *ch = [string stp_safeSubstringWithRange:NSMakeRange(i, 1)];
        unichar ascii = [ch characterAtIndex:0];
        if (ascii >= 48 && ascii <= 57) {
            [result appendString:[NSString stringWithFormat:@"%d", ascii - 48]];
        } else {
            [result appendString:[NSString stringWithFormat:@"%d", ascii - 65 + 10]];
        }
    }
    return result;
}

+ (BOOL)stringIsValidIBAN:(NSString *)string {
    NSString *sanitized = [[self class] sanitizedIBANForString:string];
    if (![string isEqualToString:sanitized]) {
        return NO;
    }
    if (![[self class] stringIsValidPartialIBAN:string]) {
        return NO;
    }
    STPParsedIBAN *iban = [[STPParsedIBAN alloc] initWithString:string];
    NSString *prefix = [iban.countryCode stringByAppendingString:iban.checkDigits];
    // Move the four initial characters to the end of the string
    NSString *rearranged = [iban.bban stringByAppendingString:prefix];
    // Replace each letter in the string with two digits
    NSString *digits = [[self class] stringByReplacingLettersWithDigits:rearranged];
    // Compute digits mod 97, using a piecewise algorithm
    // https://en.wikipedia.org/wiki/International_Bank_Account_Number#Modulo_operation_on_IBAN
    NSString *currentDigits = [digits stp_safeSubstringToIndex:9];
    NSString *remainingDigits = [digits stp_safeSubstringFromIndex:9];
    NSUInteger remainder = 0;
    while (remainingDigits.length > 0) {
        remainder = [currentDigits integerValue] % 97;
        NSString *nextDigits = [remainingDigits stp_safeSubstringToIndex:7];
        remainingDigits = [remainingDigits stp_safeSubstringFromIndex:7];
        currentDigits = [NSString stringWithFormat:@"%lu%@", (unsigned long)remainder, nextDigits];
    }
    remainder = [currentDigits integerValue] % 97;
    return remainder == 1;
}

@end
