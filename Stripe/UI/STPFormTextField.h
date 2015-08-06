//
//  STPFormTextField.h
//  Stripe
//
//  Created by Jack Flintermann on 7/16/15.
//  Copyright (c) 2015 Stripe, Inc. All rights reserved.
//

@import UIKit;

@class STPFormTextField;

@protocol STPFormTextFieldDelegate <UITextFieldDelegate>

- (void)formTextFieldDidBackspaceOnEmpty:(STPFormTextField *)formTextField;

@end

@interface STPFormTextField : UITextField

@property(nonatomic, readwrite) BOOL ignoresTouches;

@property(nonatomic, readwrite) UIColor *defaultColor;
@property(nonatomic, readwrite) UIColor *errorColor;
@property(nonatomic, readwrite) UIColor *placeholderColor;

@property(nonatomic, readwrite, assign)BOOL formatsCardNumbers;
@property(nonatomic, readwrite, assign)BOOL validText;
@property(nonatomic, readwrite, weak)id<STPFormTextFieldDelegate>formDelegate;

- (CGSize)measureTextSize;

@end
