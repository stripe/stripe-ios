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
@property(nonatomic)UIFont  *font;

@end

static UIColor *STPThemeDefaultPrimaryBackgroundColor;
static UIColor *STPThemeDefaultSecondaryBackgroundColor;
static UIColor *STPThemeDefaultPrimaryTextColor;
static UIColor *STPThemeDefaultSecondaryTextColor;
static UIColor *STPThemeDefaultAccentColor;
static UIFont  *STPThemeDefaultFont;

@implementation STPTheme

+ (void)initialize {
    [super initialize];
    STPThemeDefaultPrimaryBackgroundColor = [UIColor colorWithRed:242.0f/255.0f green:242.0f/255.0f blue:245.0f/255.0f alpha:1];
    STPThemeDefaultSecondaryBackgroundColor = [UIColor whiteColor];
    STPThemeDefaultPrimaryTextColor = [UIColor colorWithRed:43.0f/255.0f green:43.0f/255.0f blue:45.0f/255.0f alpha:1];
    STPThemeDefaultSecondaryTextColor = [UIColor colorWithRed:142.0f/255.0f green:142.0f/255.0f blue:147.0f/255.0f alpha:1];
    STPThemeDefaultAccentColor = [UIColor colorWithRed:0 green:122.0f/255.0f blue:1 alpha:1];
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
                                          font:(nullable UIFont *)font {
    self = [super init];
    if (self) {
        _primaryBackgroundColor = primaryBackgroundColor ?: [self.class defaultPrimaryBackgroundColor];
        _secondaryBackgroundColor = secondaryBackgroundColor ?: [self.class defaultSecondaryBackgroundColor];
        _primaryTextColor = primaryTextColor ?: [self.class defaultPrimaryTextColor];
        _secondaryTextColor = secondaryTextColor ?: [self.class defaultSecondaryTextColor];
        _accentColor = accentColor ?: [self.class defaultAccentColor];
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
                                           font:nil];
}

- (UIColor *)tertiaryTextColor {
    return [self.secondaryTextColor colorWithAlphaComponent:0.8];
}

- (UIFont *)smallFont {
    CGFloat pointSize = round(self.font.pointSize * 5.0f/6.0f);
    return [self.font fontWithSize:pointSize];
}

@end
