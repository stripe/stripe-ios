//
//  STPPaymentCardTextFieldViewModel.m
//  Stripe
//
//  Created by Jack Flintermann on 7/21/15.
//  Copyright (c) 2015 Stripe, Inc. All rights reserved.
//

#import "STPPaymentCardTextFieldViewModel.h"

#import "NSString+Stripe.h"
#import "STPPostalCodeValidator.h"

@implementation STPPaymentCardTextFieldViewModel

- (void)setCardNumber:(NSString *)cardNumber {
    NSString *sanitizedNumber = [STPCardValidator sanitizedNumericStringForString:cardNumber];
    STPCardBrand brand = [STPCardValidator brandForNumber:sanitizedNumber];
    NSInteger maxLength = [STPCardValidator maxLengthForCardBrand:brand];
    _cardNumber = [sanitizedNumber stp_safeSubstringToIndex:maxLength];
}

// This might contain slashes.
- (void)setRawExpiration:(NSString *)expiration {
    NSString *sanitizedExpiration = [STPCardValidator sanitizedNumericStringForString:expiration];

    switch (self.expirationFormat) {
        case STPPaymentCardTextFieldExpirationFormatMMYY:
            self.expirationMonth = [sanitizedExpiration stp_safeSubstringToIndex:2];
            self.expirationYear = [[sanitizedExpiration stp_safeSubstringFromIndex:2] stp_safeSubstringToIndex:2];
            break;

        case STPPaymentCardTextFieldExpirationFormatYYMM:
            self.expirationYear = [sanitizedExpiration stp_safeSubstringToIndex:2];
            self.expirationMonth = [[sanitizedExpiration stp_safeSubstringFromIndex:2] stp_safeSubstringToIndex:2];
            break;
    }
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
                                                                           usage:STPPostalCodeIntendedUsageBillingAddress];
}

- (void)setPostalCodeCountryCode:(NSString *)postalCodeCountryCode {
    _postalCodeCountryCode = postalCodeCountryCode;
    _postalCode = [STPPostalCodeValidator formattedSanitizedPostalCodeFromString:self.postalCode
                                                                     countryCode:postalCodeCountryCode
                                                                           usage:STPPostalCodeIntendedUsageBillingAddress];
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
            return [STPPostalCodeValidator validationStateForPostalCode:self.postalCode
                                                            countryCode:self.postalCodeCountryCode];
    }
}

- (BOOL)isValid {
    return ([self validationStateForField:STPCardFieldTypeNumber] == STPCardValidationStateValid
            && [self validationStateForField:STPCardFieldTypeExpiration] == STPCardValidationStateValid
            && [self validationStateForField:STPCardFieldTypeCVC] == STPCardValidationStateValid
            && (!self.postalCodeRequired
                || [self validationStateForField:STPCardFieldTypePostalCode] == STPCardValidationStateValid));
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
                                 NSStringFromSelector(@selector(postalCodeRequired)),
                                 NSStringFromSelector(@selector(postalCodeCountryCode)),
                                 ]];
}

@end
