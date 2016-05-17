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
@property(nonatomic)UIColor *primaryForegroundColor;
@property(nonatomic)UIColor *secondaryForegroundColor;
@property(nonatomic)UIColor *accentColor;
@property(nonatomic)UIColor *errorColor;
@property(nonatomic)UIFont  *font;
@property(nonatomic)UIFont  *mediumFont;

@end

static STPTheme *STPThemeDefaultTheme;
static UIColor *STPThemeDefaultPrimaryBackgroundColor;
static UIColor *STPThemeDefaultSecondaryBackgroundColor;
static UIColor *STPThemeDefaultPrimaryForegroundColor;
static UIColor *STPThemeDefaultSecondaryForegroundColor;
static UIColor *STPThemeDefaultAccentColor;
static UIColor *STPThemeDefaultErrorColor;
static UIFont  *STPThemeDefaultFont;
static UIFont  *STPThemeDefaultMediumFont;

@implementation STPTheme

+ (void)initialize {
    STPThemeDefaultPrimaryBackgroundColor = [UIColor colorWithRed:242.0f/255.0f green:242.0f/255.0f blue:245.0f/255.0f alpha:1];
    STPThemeDefaultSecondaryBackgroundColor = [UIColor whiteColor];
    STPThemeDefaultPrimaryForegroundColor = [UIColor colorWithRed:43.0f/255.0f green:43.0f/255.0f blue:45.0f/255.0f alpha:1];
    STPThemeDefaultSecondaryForegroundColor = [UIColor colorWithRed:142.0f/255.0f green:142.0f/255.0f blue:147.0f/255.0f alpha:1];
    STPThemeDefaultAccentColor = [UIColor colorWithRed:0 green:122.0f/255.0f blue:1 alpha:1];
    STPThemeDefaultErrorColor = [UIColor colorWithRed:1 green:72.0f/255.0f blue:68.0f/255.0f alpha:1];
    STPThemeDefaultFont = [UIFont systemFontOfSize:17];
    STPThemeDefaultMediumFont = [UIFont systemFontOfSize:17.0f weight:0.2f] ?: [UIFont boldSystemFontOfSize:17];
    STPThemeDefaultTheme = [STPTheme new];
}

+ (void)setDefaultTheme:(STPTheme *)theme {
    STPThemeDefaultTheme = theme;
}

+ (STPTheme *)defaultTheme {
    return STPThemeDefaultTheme;
}

- (instancetype)initWithPrimaryBackgroundColor:(nullable UIColor *)primaryBackgroundColor
                      secondaryBackgroundColor:(nullable UIColor *)secondaryBackgroundColor
                        primaryForegroundColor:(nullable UIColor *)primaryForegroundColor
                      secondaryForegroundColor:(nullable UIColor *)secondaryForegroundColor
                                   accentColor:(nullable UIColor *)accentColor
                                    errorColor:(nullable UIColor *)errorColor
                                          font:(nullable UIFont *)font
                                    mediumFont:(nullable UIFont *)mediumFont {
    self = [super init];
    if (self) {
        _primaryBackgroundColor = primaryBackgroundColor ?: STPThemeDefaultPrimaryBackgroundColor;
        _secondaryBackgroundColor = secondaryBackgroundColor ?: STPThemeDefaultSecondaryBackgroundColor;
        _primaryForegroundColor = primaryForegroundColor ?: STPThemeDefaultPrimaryForegroundColor;
        _secondaryForegroundColor = secondaryForegroundColor ?: STPThemeDefaultSecondaryForegroundColor;
        _accentColor = accentColor ?: STPThemeDefaultAccentColor;
        _errorColor = errorColor ?: STPThemeDefaultErrorColor;
        _font = font ?: STPThemeDefaultFont;
        _mediumFont = mediumFont ?: STPThemeDefaultMediumFont;
    }
    return self;
}

- (instancetype)init {
    return [self initWithPrimaryBackgroundColor:nil
                       secondaryBackgroundColor:nil
                         primaryForegroundColor:nil
                       secondaryForegroundColor:nil
                                    accentColor:nil
                                     errorColor:nil
                                           font:nil
                                     mediumFont:nil];
}

- (UIColor *)tertiaryBackgroundColor {
	CGFloat hue;
	CGFloat saturation;
	CGFloat brightness;
	CGFloat alpha;
	[self.primaryBackgroundColor getHue:&hue saturation:&saturation brightness:&brightness alpha:&alpha];
    return [UIColor colorWithHue:hue saturation:saturation brightness:(brightness - 0.09f) alpha:alpha];
}

- (UIColor *)tertiaryForegroundColor {
    return [self.primaryForegroundColor colorWithAlphaComponent:0.25f];
}

- (UIColor *)separatorColor {
    CGFloat hue;
    CGFloat saturation;
    CGFloat brightness;
    CGFloat alpha;
    [self.primaryBackgroundColor getHue:&hue saturation:&saturation brightness:&brightness alpha:&alpha];
    return [UIColor colorWithHue:hue saturation:saturation brightness:(brightness - 0.03f) alpha:alpha];
}

- (UIFont *)smallFont {
    return [self.font fontWithSize:self.font.pointSize - 2];
}

- (UIFont *)largeFont {
    return [self.font fontWithSize:self.font.pointSize + 15];
}

@end
