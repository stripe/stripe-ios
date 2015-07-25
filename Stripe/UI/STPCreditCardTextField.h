//
//  STPCreditCardTextField.h
//  Stripe
//
//  Created by Jack Flintermann on 7/16/15.
//  Copyright (c) 2015 Stripe, Inc. All rights reserved.
//

@import UIKit;

@interface STPCreditCardTextField : UIControl IBInspectable

@property(nonatomic, copy) UIFont *font;
@property(nonatomic, copy) UIColor *textColor;
@property(nonatomic, copy) UIColor *textErrorColor;
@property(nonatomic, copy) UIColor *placeholderColor;
@property(nonatomic, assign) UITextBorderStyle borderStyle;
@property(nonatomic, strong) UIView *inputAccessoryView;

- (BOOL)canSelectNextField;
- (BOOL)canSelectPreviousField;

- (BOOL)selectNextField;
- (BOOL)selectPreviousField;

@end
