//
//  STPThreeDSTextFieldCustomization.m
//  StripeiOS
//
//  Created by Yuki Tokuhiro on 6/18/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import "STPThreeDSTextFieldCustomization.h"

#import "STPThreeDSCustomization+Private.h"
#import <Stripe/STDSTextFieldCustomization.h>

@implementation STPThreeDSTextFieldCustomization

+ (instancetype)defaultSettings {
    return [self new];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _textFieldCustomization = [STDSTextFieldCustomization defaultSettings];
    }
    return self;
}

- (CGFloat)borderWidth {
    return self.textFieldCustomization.borderWidth;
}

- (void)setBorderWidth:(CGFloat)borderWidth {
    self.textFieldCustomization.borderWidth = borderWidth;
}

- (UIColor *)borderColor {
    return self.textFieldCustomization.borderColor;
}

- (void)setBorderColor:(UIColor *)borderColor {
    self.textFieldCustomization.borderColor = borderColor;
}

- (CGFloat)cornerRadius {
    return self.textFieldCustomization.cornerRadius;
}

- (void)setCornerRadius:(CGFloat)cornerRadius {
    self.textFieldCustomization.cornerRadius = cornerRadius;
}

- (UIKeyboardAppearance)keyboardAppearance {
    return self.textFieldCustomization.keyboardAppearance;
}

- (void)setKeyboardAppearance:(UIKeyboardAppearance)keyboardAppearance {
    self.textFieldCustomization.keyboardAppearance = keyboardAppearance;
}

- (UIColor *)placeholderTextColor {
    return self.textFieldCustomization.placeholderTextColor;
}

- (void)setPlaceholderTextColor:(UIColor *)placeholderTextColor {
    self.textFieldCustomization.placeholderTextColor = placeholderTextColor;
}

- (UIFont *)font {
    return self.textFieldCustomization.font;
}

- (void)setFont:(UIFont *)font {
    self.textFieldCustomization.font = font;
}

- (UIColor *)textColor {
    return self.textFieldCustomization.textColor;
}

- (void)setTextColor:(UIColor *)textColor {
    self.textFieldCustomization.textColor = textColor;
}

@end
