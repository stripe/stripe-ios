//
//  STPTheme.m
//  Stripe
//
//  Created by Jack Flintermann on 5/3/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import "STPTheme.h"

@interface STPTheme()

@property(nonatomic)UIColor *primaryBackgroundColor;
@property(nonatomic)UIColor *secondaryBackgroundColor;
@property(nonatomic)UIColor *primaryTextColor;
@property(nonatomic)UIColor *secondaryTextColor;
@property(nonatomic)UIColor *accentColor;
@property(nonatomic)UIColor *errorColor;
@property(nonatomic)UIFont  *font;

@end

static UIColor *STPThemeDefaultPrimaryBackgroundColor;
static UIColor *STPThemeDefaultSecondaryBackgroundColor;
static UIColor *STPThemeDefaultPrimaryTextColor;
static UIColor *STPThemeDefaultSecondaryTextColor;
static UIColor *STPThemeDefaultAccentColor;
static UIColor *STPThemeDefaultErrorColor;
static UIFont  *STPThemeDefaultFont;

@implementation STPTheme

+ (void)initialize {
    STPThemeDefaultPrimaryBackgroundColor = [UIColor colorWithRed:242.0f/255.0f green:242.0f/255.0f blue:245.0f/255.0f alpha:1];
    STPThemeDefaultSecondaryBackgroundColor = [UIColor whiteColor];
    STPThemeDefaultPrimaryTextColor = [UIColor colorWithRed:43.0f/255.0f green:43.0f/255.0f blue:45.0f/255.0f alpha:1];
    STPThemeDefaultSecondaryTextColor = [UIColor colorWithRed:142.0f/255.0f green:142.0f/255.0f blue:147.0f/255.0f alpha:1];
    STPThemeDefaultAccentColor = [UIColor colorWithRed:0 green:122.0f/255.0f blue:1 alpha:1];
    STPThemeDefaultErrorColor = [UIColor colorWithRed:1 green:72.0f/255.0f blue:68.0f/255.0f alpha:1];
    STPThemeDefaultFont = [UIFont systemFontOfSize:17];
}

+ (void)setDefaultPrimaryBackgroundColor:(UIColor *)primaryBackgroundColor {
    STPThemeDefaultPrimaryBackgroundColor = primaryBackgroundColor;
}

+ (UIColor *)defaultPrimaryBackgroundColor {
    return STPThemeDefaultPrimaryBackgroundColor;
}

+ (void)setDefaultSecondaryBackgroundColor:(UIColor *)secondaryBackgroundColor {
    STPThemeDefaultSecondaryBackgroundColor = secondaryBackgroundColor;
}

+ (UIColor *)defaultSecondaryBackgroundColor {
    return STPThemeDefaultSecondaryBackgroundColor;
}

+ (void)setDefaultPrimaryTextColor:(UIColor *)primaryTextColor {
    STPThemeDefaultPrimaryTextColor = primaryTextColor;
}

+ (UIColor *)defaultPrimaryTextColor {
    return STPThemeDefaultPrimaryTextColor;
}

+ (void)setDefaultSecondaryTextColor:(UIColor *)secondaryTextColor {
    STPThemeDefaultSecondaryTextColor = secondaryTextColor;
}

+ (UIColor *)defaultSecondaryTextColor {
    return STPThemeDefaultSecondaryTextColor;
}

+ (void)setDefaultAccentColor:(UIColor *)accentColor {
    STPThemeDefaultAccentColor = accentColor;
}

+ (UIColor *)defaultAccentColor {
    return STPThemeDefaultAccentColor;
}

+ (void)setDefaultErrorColor:(UIColor *)errorColor {
    STPThemeDefaultErrorColor = errorColor;
}

+ (UIColor *)defaultErrorColor {
    return STPThemeDefaultErrorColor;
}

+ (void)setDefaultFont:(UIFont *)font {
    STPThemeDefaultFont = font;
}

+ (UIFont *)defaultFont {
    return STPThemeDefaultFont;
}


- (instancetype)initWithPrimaryBackgroundColor:(nullable UIColor *)primaryBackgroundColor
                      secondaryBackgroundColor:(nullable UIColor *)secondaryBackgroundColor
                              primaryTextColor:(nullable UIColor *)primaryTextColor
                            secondaryTextColor:(nullable UIColor *)secondaryTextColor
                                   accentColor:(nullable UIColor *)accentColor
                                    errorColor:(nullable UIColor *)errorColor
                                          font:(nullable UIFont *)font {
    self = [super init];
    if (self) {
        _primaryBackgroundColor = primaryBackgroundColor ?: [self.class defaultPrimaryBackgroundColor];
        _secondaryBackgroundColor = secondaryBackgroundColor ?: [self.class defaultSecondaryBackgroundColor];
        _primaryTextColor = primaryTextColor ?: [self.class defaultPrimaryTextColor];
        _secondaryTextColor = secondaryTextColor ?: [self.class defaultSecondaryTextColor];
        _accentColor = accentColor ?: [self.class defaultAccentColor];
        _errorColor = errorColor ?: [self.class defaultErrorColor];
        _font = font ?: [self.class defaultFont];
    }
    return self;
}

- (instancetype)init {
    return [self initWithPrimaryBackgroundColor:nil
                       secondaryBackgroundColor:nil
                               primaryTextColor:nil
                             secondaryTextColor:nil
                                    accentColor:nil
                                     errorColor:nil
                                           font:nil];
}

- (UIColor *)tertiaryTextColor {
    return [self.secondaryTextColor colorWithAlphaComponent:0.8f];
}

- (UIFont *)smallFont {
    CGFloat pointSize = (CGFloat)round(self.font.pointSize * 5.0f/6.0f);
    return [self.font fontWithSize:pointSize];
}

- (UIFont *)largeFont {
    CGFloat pointSize = (CGFloat)round(self.font.pointSize * 2.0f);
    return [self.font fontWithSize:pointSize];
}

@end
