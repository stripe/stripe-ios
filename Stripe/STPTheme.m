//
//  STPTheme.m
//  Stripe
//
//  Created by Jack Flintermann on 5/3/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import "STPTheme.h"
#import "STPColorUtils.h"

typedef UIColor *(^STPColorBlock)(void);

@interface STPTheme()
@property (nonatomic) NSNumber *internalBarStyle;
@end

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
#ifdef __IPHONE_13_0
    if (@available(iOS 13.0, *)) {
        STPThemeDefaultPrimaryBackgroundColor = [UIColor secondarySystemBackgroundColor];
        STPThemeDefaultSecondaryBackgroundColor = [UIColor systemBackgroundColor];
        STPThemeDefaultPrimaryForegroundColor = [UIColor labelColor];
        STPThemeDefaultSecondaryForegroundColor = [UIColor secondaryLabelColor];
        STPThemeDefaultAccentColor = [UIColor systemBlueColor];
        STPThemeDefaultErrorColor = [UIColor systemRedColor];
    } else {
#endif
        STPThemeDefaultPrimaryBackgroundColor = [UIColor colorWithRed:242.0f/255.0f green:242.0f/255.0f blue:245.0f/255.0f alpha:1];
        STPThemeDefaultSecondaryBackgroundColor = [UIColor whiteColor];
        STPThemeDefaultPrimaryForegroundColor = [UIColor colorWithRed:43.0f/255.0f green:43.0f/255.0f blue:45.0f/255.0f alpha:1];
        STPThemeDefaultSecondaryForegroundColor = [UIColor colorWithRed:142.0f/255.0f green:142.0f/255.0f blue:147.0f/255.0f alpha:1];
        STPThemeDefaultAccentColor = [UIColor colorWithRed:0 green:122.0f/255.0f blue:1 alpha:1];
        STPThemeDefaultErrorColor = [UIColor colorWithRed:1 green:72.0f/255.0f blue:68.0f/255.0f alpha:1];
#ifdef __IPHONE_13_0
    }
#endif
    STPThemeDefaultFont = [UIFont systemFontOfSize:17];

    STPThemeDefaultMediumFont = [UIFont systemFontOfSize:17.0f weight:0.2f] ?: [UIFont boldSystemFontOfSize:17];
}

+ (STPTheme *)defaultTheme {
    static STPTheme  *STPThemeDefaultTheme;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        STPThemeDefaultTheme = [self new];
    });
    return STPThemeDefaultTheme;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _primaryBackgroundColor = STPThemeDefaultPrimaryBackgroundColor;
        _secondaryBackgroundColor = STPThemeDefaultSecondaryBackgroundColor;
        _primaryForegroundColor = STPThemeDefaultPrimaryForegroundColor;
        _secondaryForegroundColor = STPThemeDefaultSecondaryForegroundColor;
        _accentColor = STPThemeDefaultAccentColor;
        _errorColor = STPThemeDefaultErrorColor;
        _translucentNavigationBar = YES;
    }
    return self;
}

- (UIColor *)primaryBackgroundColor {
    return _primaryBackgroundColor ?: STPThemeDefaultPrimaryBackgroundColor;
}

- (UIColor *)secondaryBackgroundColor {
    return _secondaryBackgroundColor ?: STPThemeDefaultSecondaryBackgroundColor;
}

- (UIColor *)tertiaryBackgroundColor {
    STPColorBlock colorBlock = ^{
        CGFloat hue;
        CGFloat saturation;
        CGFloat brightness;
        CGFloat alpha;
        [self.primaryBackgroundColor getHue:&hue saturation:&saturation brightness:&brightness alpha:&alpha];
        return [UIColor colorWithHue:hue saturation:saturation brightness:(brightness - 0.09f) alpha:alpha];
    };
#ifdef __IPHONE_13_0
    if (@available(iOS 13.0, *)) {
        return [UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * __unused _Nonnull traitCollection) {
            return colorBlock();
        }];
    } else {
#endif
        return colorBlock();
#ifdef __IPHONE_13_0
    }
#endif
}

- (UIColor *)primaryForegroundColor {
    return _primaryForegroundColor ?: STPThemeDefaultPrimaryForegroundColor;
}

- (UIColor *)secondaryForegroundColor {
    return _secondaryForegroundColor ?: STPThemeDefaultSecondaryForegroundColor;
}

- (UIColor *)tertiaryForegroundColor {
#ifdef __IPHONE_13_0
    if (@available(iOS 13.0, *)) {
        return [UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * __unused _Nonnull traitCollection) {
            return [self.primaryForegroundColor colorWithAlphaComponent:0.25f];
        }];
    } else {
#endif
    return [self.primaryForegroundColor colorWithAlphaComponent:0.25f];
#ifdef __IPHONE_13_0
    }
#endif
}

- (UIColor *)quaternaryBackgroundColor {
    STPColorBlock colorBlock = ^{
        CGFloat hue;
        CGFloat saturation;
        CGFloat brightness;
        CGFloat alpha;
        [self.primaryBackgroundColor getHue:&hue saturation:&saturation brightness:&brightness alpha:&alpha];
        return [UIColor colorWithHue:hue saturation:saturation brightness:(brightness - 0.03f) alpha:alpha];
    };
#ifdef __IPHONE_13_0
    if (@available(iOS 13.0, *)) {
        return [UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * __unused _Nonnull traitCollection) {
            return colorBlock();
        }];
    } else {
#endif
        return colorBlock();
#ifdef __IPHONE_13_0
    }
#endif
}

- (UIColor *)accentColor {
    return _accentColor ?: STPThemeDefaultAccentColor;
}

- (UIColor *)errorColor {
    return _errorColor ?: STPThemeDefaultErrorColor;
}

- (UIFont *)font {
    if (_font != nil) {
        return [_font copy];
    } else {
        UIFontMetrics *fontMetrics = [UIFontMetrics metricsForTextStyle:UIFontTextStyleBody];
        return [fontMetrics scaledFontForFont:STPThemeDefaultFont];
    }
}

- (UIFont *)emphasisFont {
    if (_emphasisFont != nil) {
        return [_emphasisFont copy];
    } else {
        UIFontMetrics *fontMetrics = [UIFontMetrics metricsForTextStyle:UIFontTextStyleBody];
        return [fontMetrics scaledFontForFont:STPThemeDefaultMediumFont];
    }
}

- (UIFont *)smallFont {
    return [self.font fontWithSize:self.font.pointSize - 2];
}

- (UIFont *)largeFont {
    return [self.font fontWithSize:self.font.pointSize + 15];
}

- (UIBarStyle)barStyleForColor:(UIColor *)color {
    if ([STPColorUtils colorIsBright:color]) {
        return UIBarStyleDefault;
    } else {
        return UIBarStyleBlack;
    }
}

- (void)setBarStyle:(UIBarStyle)barStyle {
    _internalBarStyle = @(barStyle);
}

- (UIBarStyle)barStyle {
    if (_internalBarStyle != nil) {
        return [_internalBarStyle integerValue];
    }
    return [self barStyleForColor:self.secondaryBackgroundColor];
}

- (id)copyWithZone:(__unused NSZone *)zone {
    STPTheme *copyTheme = [self.class new];
    copyTheme.primaryBackgroundColor = self.primaryBackgroundColor;
    copyTheme.secondaryBackgroundColor = self.secondaryBackgroundColor;
    copyTheme.primaryForegroundColor = self.primaryForegroundColor;
    copyTheme.secondaryForegroundColor = self.secondaryForegroundColor;
    copyTheme.accentColor = self.accentColor;
    copyTheme.errorColor = self.errorColor;
    copyTheme->_font = [_font copy];
    copyTheme->_emphasisFont = [_emphasisFont copy];
    copyTheme.translucentNavigationBar = self.translucentNavigationBar;
    return copyTheme;
}

@end
