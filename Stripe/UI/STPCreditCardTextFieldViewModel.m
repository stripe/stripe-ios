//
//  STPCreditCardTextFieldViewModel.m
//  Stripe
//
//  Created by Jack Flintermann on 7/21/15.
//  Copyright (c) 2015 Stripe, Inc. All rights reserved.
//

#import "STPCreditCardTextFieldViewModel.h"

@implementation STPCreditCardTextFieldViewModel

- (void)setCardNumber:(NSString *)cardNumber {
    cardNumber = [STPCardValidator sanitizedNumericStringForString:cardNumber];
    STPCardBrand brand = [STPCardValidator brandForNumber:cardNumber];
    NSInteger maxLength = [STPCardValidator lengthForCardBrand:brand];
    
    if ((NSInteger)cardNumber.length > maxLength) {
        cardNumber = [cardNumber substringToIndex:maxLength];
    }
    _cardNumber = cardNumber;
}

- (void)setExpirationMonth:(NSString *)expirationMonth {
    expirationMonth = [STPCardValidator sanitizedNumericStringForString:expirationMonth];
    if (expirationMonth.length == 1 && ![expirationMonth isEqualToString:@"0"] && ![expirationMonth isEqualToString:@"1"]) {
        expirationMonth = [@"0" stringByAppendingString:expirationMonth];
    } else if (expirationMonth.length > 2) {
        expirationMonth = [expirationMonth substringToIndex:2];
    }
    _expirationMonth = expirationMonth;
}

- (void)setExpirationYear:(NSString *)expirationYear {
    expirationYear = [STPCardValidator sanitizedNumericStringForString:expirationYear];
    if (expirationYear.length > 2) {
        expirationYear = [expirationYear substringToIndex:2];
    }
    _expirationYear = [STPCardValidator sanitizedNumericStringForString:expirationYear];
}

- (void)setCvc:(NSString *)cvc {
    cvc = [STPCardValidator sanitizedNumericStringForString:cvc];
    NSInteger maxLength = [STPCardValidator maxCvcLengthForCardBrand:self.brand];
    if ((NSInteger)cvc.length > maxLength) {
        cvc = [cvc substringToIndex:maxLength];
    }
    _cvc = cvc;
}

- (STPCardBrand)brand {
    return [STPCardValidator brandForNumber:self.cardNumber];
}

- (STPCardValidationState)validationStateForField:(STPCardFieldType)fieldType {
    switch (fieldType) {
        case STPCardFieldTypeNumber:
            return [STPCardValidator validationStateForNumber:self.cardNumber];
            break;
        case STPCardFieldTypeMonth:
            return [STPCardValidator validationStateForExpirationMonth:self.expirationMonth];
            break;
        case STPCardFieldTypeYear:
            return [STPCardValidator validationStateForExpirationYear:self.expirationYear inMonth:self.expirationMonth];
            break;
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
