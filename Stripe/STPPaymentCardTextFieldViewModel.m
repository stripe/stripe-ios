//
//  STPPaymentCardTextFieldViewModel.m
//  Stripe
//
//  Created by Jack Flintermann on 7/21/15.
//  Copyright (c) 2015 Stripe, Inc. All rights reserved.
//

#import "STPPaymentCardTextFieldViewModel.h"

#import "NSString+Stripe.h"
#import "STPCardValidator+Private.h"
#import "STPPostalCodeValidator.h"

@implementation STPPaymentCardTextFieldViewModel

- (void)setCardNumber:(NSString *)cardNumber {
    NSString *sanitizedNumber = [STPCardValidator sanitizedNumericStringForString:cardNumber];
    STPCardBrand brand = [STPCardValidator brandForNumber:sanitizedNumber];
    NSInteger maxLength = [STPCardValidator maxLengthForCardBrand:brand];
    _cardNumber = [sanitizedNumber stp_safeSubstringToIndex:maxLength];
}

- (NSString *)compressedCardNumber {
    NSString *cardNumber = self.cardNumber;
    if (cardNumber.length == 0) {
        cardNumber = self.defaultPlaceholder;
    }

    STPCardBrand currentBrand = [STPCardValidator brandForNumber:cardNumber];
    if ([self validationStateForField:STPCardFieldTypeNumber] == STPCardValidationStateValid) {
        // Use fragment length
        NSUInteger length = [STPCardValidator fragmentLengthForCardBrand:currentBrand];
        NSUInteger index = cardNumber.length - length;

        if (index < cardNumber.length) {
            return [cardNumber stp_safeSubstringFromIndex:index];
        }
    } else {
        // use the card number format
        NSArray<NSNumber *> *cardNumberFormat = [STPCardValidator cardNumberFormatForCardNumber:cardNumber];

        NSUInteger index = 0;
        for (NSNumber *segment in cardNumberFormat) {
            NSUInteger segmentLength = [segment unsignedIntegerValue];
            if (index + segmentLength >= cardNumber.length) {
                return [cardNumber stp_safeSubstringFromIndex:index];
            }
            index += segmentLength;
        }
    }

    return nil;
}

// This might contain slashes.
- (void)setRawExpiration:(NSString *)expiration {
    NSString *sanitizedExpiration = [STPCardValidator sanitizedNumericStringForString:expiration];
    self.expirationMonth = [sanitizedExpiration stp_safeSubstringToIndex:2];
    self.expirationYear = [[sanitizedExpiration stp_safeSubstringFromIndex:2] stp_safeSubstringToIndex:2];
}

- (NSString *)rawExpiration {
    NSMutableArray *array = [@[] mutableCopy];
    if (self.expirationMonth && ![self.expirationMonth isEqualToString:@""]) {
        [array addObject:self.expirationMonth];
    }
    
    if ([STPCardValidator validationStateForExpirationMonth:self.expirationMonth] == STPCardValidationStateValid) {
        [array addObject:self.expirationYear];
    }
    return [array componentsJoinedByString:@"/"];
}

- (void)setExpirationMonth:(NSString *)expirationMonth {
    NSString *sanitizedExpiration = [STPCardValidator sanitizedNumericStringForString:expirationMonth];
    if (sanitizedExpiration.length == 1 && ![sanitizedExpiration isEqualToString:@"0"] && ![sanitizedExpiration isEqualToString:@"1"]) {
        sanitizedExpiration = [@"0" stringByAppendingString:sanitizedExpiration];
    }
    _expirationMonth = [sanitizedExpiration stp_safeSubstringToIndex:2];
}

- (void)setExpirationYear:(NSString *)expirationYear {
    _expirationYear = [[STPCardValidator sanitizedNumericStringForString:expirationYear] stp_safeSubstringToIndex:2];
}

- (void)setCvc:(NSString *)cvc {
    NSInteger maxLength = [STPCardValidator maxCVCLengthForCardBrand:self.brand];
    _cvc = [[STPCardValidator sanitizedNumericStringForString:cvc] stp_safeSubstringToIndex:maxLength];
}

- (void)setPostalCode:(NSString *)postalCode {
    _postalCode = [STPPostalCodeValidator formattedSanitizedPostalCodeFromString:postalCode
                                                                     countryCode:self.postalCodeCountryCode
                                                                           usage:STPPostalCodeIntendedUsageCardField];
}

- (void)setPostalCodeCountryCode:(NSString *)postalCodeCountryCode {
    _postalCodeCountryCode = postalCodeCountryCode;
    _postalCode = [STPPostalCodeValidator formattedSanitizedPostalCodeFromString:self.postalCode
                                                                     countryCode:postalCodeCountryCode
                                                                           usage:STPPostalCodeIntendedUsageCardField];
}

- (STPCardBrand)brand {
    return [STPCardValidator brandForNumber:self.cardNumber];
}

- (STPCardValidationState)validationStateForField:(STPCardFieldType)fieldType {
    switch (fieldType) {
        case STPCardFieldTypeNumber:
            return [STPCardValidator validationStateForNumber:self.cardNumber validatingCardBrand:YES];
            break;
        case STPCardFieldTypeExpiration: {
            STPCardValidationState monthState = [STPCardValidator validationStateForExpirationMonth:self.expirationMonth];
            STPCardValidationState yearState = [STPCardValidator validationStateForExpirationYear:self.expirationYear inMonth:self.expirationMonth];
            if (monthState == STPCardValidationStateValid && yearState == STPCardValidationStateValid) {
                return STPCardValidationStateValid;
            } else if (monthState == STPCardValidationStateInvalid || yearState == STPCardValidationStateInvalid) {
                return STPCardValidationStateInvalid;
            } else {
                return STPCardValidationStateIncomplete;
            }
            break;
        }
        case STPCardFieldTypeCVC:
            return [STPCardValidator validationStateForCVC:self.cvc cardBrand:self.brand];
        case STPCardFieldTypePostalCode:
            if (self.postalCode.length > 0) {
                return STPCardValidationStateValid;
            } else {
                return STPCardValidationStateIncomplete;
            }
    }
}

- (BOOL)isValid {
    return ([self validationStateForField:STPCardFieldTypeNumber] == STPCardValidationStateValid
            && [self validationStateForField:STPCardFieldTypeExpiration] == STPCardValidationStateValid
            && [self validationStateForField:STPCardFieldTypeCVC] == STPCardValidationStateValid
            && (!self.postalCodeRequired
                || [self validationStateForField:STPCardFieldTypePostalCode] == STPCardValidationStateValid));
}

- (BOOL)postalCodeRequired {
    return (self.postalCodeRequested && [STPPostalCodeValidator postalCodeIsRequiredForCountryCode:self.postalCodeCountryCode]);
}

- (NSString *)defaultPlaceholder {
    return @"4242424242424242";
}

+ (NSSet<NSString *> *)keyPathsForValuesAffectingValid {
    return [NSSet setWithArray:@[
                                 NSStringFromSelector(@selector(cardNumber)),
                                 NSStringFromSelector(@selector(expirationMonth)),
                                 NSStringFromSelector(@selector(expirationYear)),
                                 NSStringFromSelector(@selector(cvc)),
                                 NSStringFromSelector(@selector(brand)),
                                 NSStringFromSelector(@selector(postalCode)),
                                 NSStringFromSelector(@selector(postalCodeRequested)),
                                 NSStringFromSelector(@selector(postalCodeCountryCode)),
                                 ]];
}

@end
