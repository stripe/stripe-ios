//
//  STPLabeledFormTextFieldView.h
//  StripeiOS
//
//  Created by Cameron Sabol on 3/12/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

#import "STPViewWithSeparator.h"

@class STPFormTextField;

NS_ASSUME_NONNULL_BEGIN

static const CGFloat kLabeledFormFieldHeight = 44.f;
static const CGFloat kLabeledFormVeriticalMargin = 4.f;
static const CGFloat kLabeledFormHorizontalMargin = 12.f;

@interface STPLabeledFormTextFieldView: STPViewWithSeparator

- (instancetype)initWithFormLabel:(NSString *)formLabelText textField:(STPFormTextField *)textField;

@property (nonatomic) UIColor *formBackgroundColor;
// Initializes to textField.defaultColor
@property (nonatomic) UIColor *formLabelTextColor;
// Initializes to textField.font
@property (nonatomic) UIFont *formLabelFont;

@property (nonatomic, readonly) NSLayoutDimension *labelWidthDimension;

@end

NS_ASSUME_NONNULL_END
