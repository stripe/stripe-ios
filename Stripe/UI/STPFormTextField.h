//
//  STPFormTextField.h
//  Stripe
//
//  Created by Jack Flintermann on 7/16/15.
//  Copyright (c) 2015 Stripe, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class STPFormTextField;

@protocol STPFormTextFieldDelegate <UITextFieldDelegate>

- (void)formTextFieldDidBackspaceOnEmpty:(nonnull STPFormTextField *)formTextField;

@end

@interface STPFormTextField : UITextField

@property(nonatomic, readwrite, nullable) UIColor *defaultColor;
@property(nonatomic, readwrite, nullable) UIColor *errorColor;
@property(nonatomic, readwrite, nullable) UIColor *placeholderColor;

@property(nonatomic, readwrite, assign)BOOL formatsCardNumbers;
@property(nonatomic, readwrite, assign)BOOL validText;
@property(nonatomic, readwrite, weak, nullable)id<STPFormTextFieldDelegate>formDelegate;

- (CGSize)measureTextSize;

@end
