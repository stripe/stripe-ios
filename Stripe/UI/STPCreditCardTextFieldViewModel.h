//
//  STPCreditCardTextFieldViewModel.h
//  Stripe
//
//  Created by Jack Flintermann on 7/21/15.
//  Copyright (c) 2015 Stripe, Inc. All rights reserved.
//

@import Foundation;
@import UIKit;

#import "STPCard.h"
#import "STPCardValidator.h"

typedef NS_ENUM(NSInteger, STPCardFieldType) {
    STPCardFieldTypeNumber,
    STPCardFieldTypeMonth,
    STPCardFieldTypeYear,
    STPCardFieldTypeCVC,
};

@interface STPCreditCardTextFieldViewModel : NSObject

@property(nonatomic, readwrite)NSString *cardNumber;
@property(nonatomic, readwrite)NSString *expirationMonth;
@property(nonatomic, readwrite)NSString *expirationYear;
@property(nonatomic, readwrite)NSString *cvc;
@property(nonatomic, readonly) STPCardBrand brand;

- (STPCardValidationState)validationStateForField:(STPCardFieldType)fieldType;
- (UIImage *)brandImage;
- (UIImage *)cvcImage;

@end
