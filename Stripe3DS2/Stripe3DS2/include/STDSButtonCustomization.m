//
//  STDSButtonCustomization.m
//  Stripe3DS2
//
//  Created by Andrew Harrison on 3/14/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

#import "STDSButtonCustomization.h"

#import "STDSUICustomization.h"
#import "UIColor+DefaultColors.h"
#import "UIFont+DefaultFonts.h"

static const CGFloat kDefaultButtonCornerRadius = 8.0;
static const CGFloat kDefaultButtonFontScale = (CGFloat)0.9;

NS_ASSUME_NONNULL_BEGIN

@implementation STDSButtonCustomization

+ (instancetype)defaultSettingsForButtonType:(STDSUICustomizationButtonType)type {
    UIColor *backgroundColor = [UIColor _stds_blueColor];
    CGFloat cornerRadius = kDefaultButtonCornerRadius;
    UIFont *font = [UIFont _stds_defaultBoldLabelTextFontWithScale:kDefaultButtonFontScale];
    UIColor *textColor = UIColor.whiteColor;
    switch (type) {
        case STDSUICustomizationButtonTypeContinue:
        case STDSUICustomizationButtonTypeSubmit:
        case STDSUICustomizationButtonTypeNext:
            break;
        case STDSUICustomizationButtonTypeResend:
            backgroundColor = UIColor.clearColor;
            textColor = [UIColor _stds_blueColor];
            font = nil;
            break;
        case STDSUICustomizationButtonTypeCancel:
            backgroundColor = UIColor.clearColor;
            textColor = nil;
            font = nil;
            break;
    }
    STDSButtonCustomization *buttonCustomization = [[self alloc] initWithBackgroundColor:backgroundColor cornerRadius:cornerRadius];
    buttonCustomization.font = font;
    buttonCustomization.textColor = textColor;
    return buttonCustomization;
}

- (instancetype)initWithBackgroundColor:(UIColor *)backgroundColor cornerRadius:(CGFloat)cornerRadius {
    self = [super init];
    if (self) {
        _backgroundColor = backgroundColor;
        _cornerRadius = cornerRadius;
    }
    return self;
}

- (id)copyWithZone:(nullable NSZone *)zone {
    STDSButtonCustomization *copy = [super copyWithZone:zone];
    copy.backgroundColor = self.backgroundColor;
    copy.cornerRadius = self.cornerRadius;
    copy.titleStyle = self.titleStyle;
    
    return copy;
}

@end

NS_ASSUME_NONNULL_END
