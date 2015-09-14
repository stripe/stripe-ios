//
//  STPPaymentCardTextFieldViewModel.m
//  Stripe
//
//  Created by Jack Flintermann on 7/21/15.
//  Copyright (c) 2015 Stripe, Inc. All rights reserved.
//

#import "STPPaymentCardTextFieldViewModel.h"
#import "STPCardValidator.h"

#define FAUXPAS_IGNORED_IN_METHOD(...)

@interface NSString(StripeSubstring)
- (NSString *)stp_safeSubstringToIndex:(NSUInteger)index;
- (NSString *)stp_safeSubstringFromIndex:(NSUInteger)index;
@end

@implementation NSString(StripeSubstring)

- (NSString *)stp_safeSubstringToIndex:(NSUInteger)index {
    return [self substringToIndex:MIN(self.length, index)];
}

- (NSString *)stp_safeSubstringFromIndex:(NSUInteger)index {
    return (index > self.length) ? @"" : [self substringFromIndex:index];
}

@end

@implementation STPPaymentCardTextFieldViewModel

- (void)setCardNumber:(NSString *)cardNumber {
    NSString *sanitizedNumber = [STPCardValidator sanitizedNumericStringForString:cardNumber];
    STPCardBrand brand = [STPCardValidator brandForNumber:sanitizedNumber];
    NSInteger maxLength = [STPCardValidator lengthForCardBrand:brand];
    _cardNumber = [sanitizedNumber stp_safeSubstringToIndex:maxLength];
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
    }
}

- (UIImage *)brandImage {
    FAUXPAS_IGNORED_IN_METHOD(APIAvailability);
    NSString *imageName;
    BOOL templateSupported = [[UIImage new] respondsToSelector:@selector(imageWithRenderingMode:)];
    switch (self.brand) {
        case STPCardBrandAmex:
            imageName = @"stp_card_amex";
            break;
        case STPCardBrandDinersClub:
            imageName = @"stp_card_diners";
            break;
        case STPCardBrandDiscover:
            imageName = @"stp_card_discover";
            break;
        case STPCardBrandJCB:
            imageName = @"stp_card_jcb";
            break;
        case STPCardBrandMasterCard:
            imageName = @"stp_card_mastercard";
            break;
        case STPCardBrandUnknown:
            imageName = templateSupported ? @"stp_card_placeholder_template" : @"stp_card_placeholder";
            break;
        case STPCardBrandVisa:
            imageName = @"stp_card_visa";
    }
    UIImage *image = [self.class safeImageNamed:imageName];
    if (self.brand == STPCardBrandUnknown && templateSupported) {
        image = [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    }
    return image;
}

- (UIImage *)cvcImage {
    NSString *imageName = self.brand == STPCardBrandAmex ? @"stp_card_cvc_amex" : @"stp_card_cvc";
    return [self.class safeImageNamed:imageName];
}

+ (UIImage *)safeImageNamed:(NSString *)imageName {
    if ([[UIImage class] respondsToSelector:@selector(imageNamed:inBundle:compatibleWithTraitCollection:)]) {
        return [UIImage imageNamed:imageName inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
    }
    return [UIImage imageNamed:imageName];
}

- (BOOL)isValid {
    return ([self validationStateForField:STPCardFieldTypeNumber] == STPCardValidationStateValid &&
            [self validationStateForField:STPCardFieldTypeExpiration] == STPCardValidationStateValid &&
            [self validationStateForField:STPCardFieldTypeCVC] == STPCardValidationStateValid);
}

- (NSString *)defaultPlaceholder {
    return @"1234567812345678";
}

- (NSString *)numberWithoutLastDigits {
    NSUInteger length = [STPCardValidator fragmentLengthForCardBrand:[STPCardValidator brandForNumber:self.cardNumber]];
    NSUInteger toIndex = self.cardNumber.length - length;
    
    return (toIndex < self.cardNumber.length) ?
        [self.cardNumber substringToIndex:toIndex] :
        [self.defaultPlaceholder stp_safeSubstringToIndex:[self defaultPlaceholder].length - length];

}

@end
