//
//  STPPaymentCardTextFieldViewModel.h
//  Stripe
//
//  Created by Jack Flintermann on 7/21/15.
//  Copyright (c) 2015 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "STPCard.h"
#import "STPCardValidator.h"
#import "STPPostalCodeValidator.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, STPCardFieldType) {
    STPCardFieldTypeNumber,
    STPCardFieldTypeExpiration,
    STPCardFieldTypeCVC,
    STPCardFieldTypePostalCode,
};

@interface STPPaymentCardTextFieldViewModel : NSObject

@property (nonatomic, copy, nullable) NSString *cardNumber;
@property (nonatomic, copy, nullable) NSString *rawExpiration;
@property (nonatomic, readonly, nullable) NSString *expirationMonth;
@property (nonatomic, readonly, nullable) NSString *expirationYear;
@property (nonatomic, copy, nullable) NSString *cvc;
@property (nonatomic) BOOL postalCodeRequested;
@property (nonatomic, readonly) BOOL postalCodeRequired;
@property (nonatomic, copy, nullable) NSString *postalCode;
@property (nonatomic, copy, nullable) NSString *postalCodeCountryCode;
@property (nonatomic, readonly) STPCardBrand brand;
@property (nonatomic, readonly) BOOL isValid;

- (NSString *)defaultPlaceholder;
- (nullable NSString *)compressedCardNumberWithPlaceholder:(nullable NSString *)placeholder;

- (STPCardValidationState)validationStateForField:(STPCardFieldType)fieldType;

@end

NS_ASSUME_NONNULL_END
