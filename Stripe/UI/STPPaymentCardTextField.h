//
//  STPPaymentCardTextField.h
//  Stripe
//
//  Created by Jack Flintermann on 7/16/15.
//  Copyright (c) 2015 Stripe, Inc. All rights reserved.
//

@import UIKit;

@class STPPaymentCardTextField;

@protocol STPPaymentCardTextFieldDelegate <NSObject>

- (void)paymentCardTextFieldDidValidateSuccessfully:(STPPaymentCardTextField *)textField;
@optional
- (void)paymentCardTextFieldDidChange:(STPPaymentCardTextField *)textField;

@end

@interface STPPaymentCardTextField : UIControl

@property(nonatomic, weak) id<STPPaymentCardTextFieldDelegate> delegate;

@property(nonatomic, copy) UIFont *font UI_APPEARANCE_SELECTOR;
@property(nonatomic, copy) UIColor *textColor UI_APPEARANCE_SELECTOR;
@property(nonatomic, copy) UIColor *textErrorColor UI_APPEARANCE_SELECTOR;
@property(nonatomic, copy) UIColor *placeholderColor UI_APPEARANCE_SELECTOR;
@property(nonatomic, assign) UITextBorderStyle borderStyle UI_APPEARANCE_SELECTOR;
@property(nonatomic, strong) UIView *inputAccessoryView;

- (BOOL)canSelectNextField;
- (BOOL)canSelectPreviousField;

- (BOOL)selectNextField;
- (BOOL)selectPreviousField;

- (void)clear;

- (BOOL)hasValidContents;

@property(nonatomic, readonly) NSString *cardNumber;
@property(nonatomic, readonly) NSUInteger expirationMonth;
@property(nonatomic, readonly) NSUInteger expirationYear;
@property(nonatomic, readonly) NSString *cvc;

@end
