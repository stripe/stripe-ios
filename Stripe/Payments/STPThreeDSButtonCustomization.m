//
//  STPThreeDSButtonCustomization.m
//  StripeiOS
//
//  Created by Yuki Tokuhiro on 6/17/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import "STPThreeDSButtonCustomization.h"
#import "STPThreeDSCustomization+Private.h"

#import <Stripe/STDSButtonCustomization.h>

@implementation STPThreeDSButtonCustomization

+ (instancetype)defaultSettingsForButtonType:(STPThreeDSCustomizationButtonType)type {
    STDSButtonCustomization *stdsButtonCustomization = [STDSButtonCustomization defaultSettingsForButtonType:(STDSUICustomizationButtonType)type];
    
    STPThreeDSButtonCustomization *buttonCustomization = [[STPThreeDSButtonCustomization alloc] initWithBackgroundColor:stdsButtonCustomization.backgroundColor cornerRadius:stdsButtonCustomization.cornerRadius];
    buttonCustomization.buttonCustomization = stdsButtonCustomization;
    return buttonCustomization;
}

- (instancetype)initWithBackgroundColor:(UIColor *)backgroundColor cornerRadius:(CGFloat)cornerRadius {
    self = [super init];
    if (self) {
        _buttonCustomization = [[STDSButtonCustomization alloc] initWithBackgroundColor:backgroundColor cornerRadius:cornerRadius];
    }
    return self;
}

- (UIColor *)backgroundColor {
    return self.buttonCustomization.backgroundColor;
}

- (void)setBackgroundColor:(UIColor *)backgroundColor {
    self.buttonCustomization.backgroundColor = backgroundColor;
}

- (CGFloat)cornerRadius {
    return self.buttonCustomization.cornerRadius;
}

- (void)setCornerRadius:(CGFloat)cornerRadius {
    self.buttonCustomization.cornerRadius = cornerRadius;
}

- (STPThreeDSButtonTitleStyle)titleStyle {
    return (STPThreeDSButtonTitleStyle)self.buttonCustomization.titleStyle;
}

- (void)setTitleStyle:(STPThreeDSButtonTitleStyle)titleStyle {
    self.buttonCustomization.titleStyle = (STDSButtonTitleStyle)titleStyle;
}

- (UIFont *)font {
    return self.buttonCustomization.font;
}

- (void)setFont:(UIFont *)font {
    self.buttonCustomization.font = font;
}

- (UIColor *)textColor {
    return self.buttonCustomization.textColor;
}

- (void)setTextColor:(UIColor *)textColor {
    self.buttonCustomization.textColor = textColor;
}

@end
