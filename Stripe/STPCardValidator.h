//
//  STPCardValidator.h
//  Stripe
//
//  Created by Jack Flintermann on 7/15/15.
//  Copyright (c) 2015 Stripe, Inc. All rights reserved.
//

@import Foundation;

#import "STPCardBrand.h"

typedef NS_ENUM(NSInteger, STPCardValidationState) {
    STPCardValidationStateValid,
    STPCardValidationStateInvalid,
    STPCardValidationStatePossible,
};

@interface STPCardValidator : NSObject

+ (NSString *)sanitizedNumericStringForString:(NSString *)string;

+ (STPCardValidationState)validationStateForNumber:(NSString *)cardNumber;
+ (STPCardBrand)brandForNumber:(NSString *)cardNumber;
+ (NSInteger)lengthForCardBrand:(STPCardBrand)brand;
+ (NSInteger)fragmentLengthForCardBrand:(STPCardBrand)brand;

+ (STPCardValidationState)validationStateForExpirationMonth:(NSString *)expirationMonth;
+ (STPCardValidationState)validationStateForExpirationYear:(NSString *)expirationYear inMonth:(NSString *)expirationMonth;

// For testing
+ (STPCardValidationState)validationStateForExpirationYear:(NSString *)expirationYear inMonth:(NSString *)expirationMonth inCurrentYear:(NSInteger)currentYear currentMonth:(NSInteger)currentMonth;

+ (NSUInteger)maxCvcLengthForCardBrand:(STPCardBrand)brand;
+ (STPCardValidationState)validationStateForCVC:(NSString *)cvc cardBrand:(STPCardBrand)brand;

@end
