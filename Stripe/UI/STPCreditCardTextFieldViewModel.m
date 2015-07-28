//
//  STPCreditCardTextFieldViewModel.m
//  Stripe
//
//  Created by Jack Flintermann on 7/21/15.
//  Copyright (c) 2015 Stripe, Inc. All rights reserved.
//

#import "STPCreditCardTextFieldViewModel.h"

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

@implementation STPCreditCardTextFieldViewModel

- (void)setCardNumber:(NSString *)cardNumber {
    cardNumber = [STPCardValidator sanitizedNumericStringForString:cardNumber];
    STPCardBrand brand = [STPCardValidator brandForNumber:cardNumber];
    NSInteger maxLength = [STPCardValidator lengthForCardBrand:brand];
    _cardNumber = [cardNumber stp_safeSubstringToIndex:maxLength];
}

- (void)setRawExpiration:(NSString *)expiration {
    expiration = [STPCardValidator sanitizedNumericStringForString:expiration];
    _rawExpiration = expiration;
    self.expirationMonth = [expiration stp_safeSubstringToIndex:2];
    self.expirationYear = [[expiration stp_safeSubstringFromIndex:2] stp_safeSubstringToIndex:2];
}

- (void)setExpirationMonth:(NSString *)expirationMonth {
    expirationMonth = [STPCardValidator sanitizedNumericStringForString:expirationMonth];
    if (expirationMonth.length == 1 && ![expirationMonth isEqualToString:@"0"] && ![expirationMonth isEqualToString:@"1"]) {
        expirationMonth = [@"0" stringByAppendingString:expirationMonth];
    }
    _expirationMonth = [expirationMonth stp_safeSubstringToIndex:2];
}

- (void)setExpirationYear:(NSString *)expirationYear {
    expirationYear = [STPCardValidator sanitizedNumericStringForString:expirationYear];
    _expirationYear = [expirationYear stp_safeSubstringToIndex:2];
}

- (void)setCvc:(NSString *)cvc {
    cvc = [STPCardValidator sanitizedNumericStringForString:cvc];
    NSInteger maxLength = [STPCardValidator maxCvcLengthForCardBrand:self.brand];
    _cvc = [cvc stp_safeSubstringToIndex:maxLength];
}

- (STPCardBrand)brand {
    return [STPCardValidator brandForNumber:self.cardNumber];
}

- (STPCardValidationState)validationStateForExpirationMonth {
    return [STPCardValidator validationStateForExpirationMonth:self.expirationMonth];
}

- (STPCardValidationState)validationStateForExpirationYear {
    return [STPCardValidator validationStateForExpirationYear:self.expirationYear inMonth:self.expirationMonth];
}

- (STPCardValidationState)validationStateForField:(STPCardFieldType)fieldType {
    switch (fieldType) {
        case STPCardFieldTypeNumber:
            return [STPCardValidator validationStateForNumber:self.cardNumber];
            break;
        case STPCardFieldTypeExpiration: {
            //TODO
            return STPCardValidationStatePossible;
            break;
        }
        case STPCardFieldTypeCVC:
            return [STPCardValidator validationStateForCVC:self.cvc cardBrand:self.brand];
    }
}

- (UIImage *)brandImage {
    NSString *imageName;
    switch (self.brand) {
        case STPCardBrandAmex:
            imageName = @"amex";
            break;
        case STPCardBrandDinersClub:
            imageName = @"diners";
            break;
        case STPCardBrandDiscover:
            imageName = @"discover";
            break;
        case STPCardBrandJCB:
            imageName = @"jcb";
            break;
        case STPCardBrandMasterCard:
            imageName = @"mastercard";
            break;
        case STPCardBrandUnknown:
            imageName = @"placeholder";
            break;
        case STPCardBrandVisa:
            imageName = @"visa";
    }
    //todo: bundle stuff
    //    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    return [UIImage imageNamed:imageName];
}

- (UIImage *)cvcImage {
    NSString *imageName = self.brand == STPCardBrandAmex ? @"cvc-amex" : @"cvc";
    //todo: bundle stuff
    //    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    return [UIImage imageNamed:imageName];
}

@end
