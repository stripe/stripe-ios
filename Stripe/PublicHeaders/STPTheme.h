//
//  STPTheme.h
//  Stripe
//
//  Created by Jack Flintermann on 5/3/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface STPTheme : NSObject

/**
 *  Set the globally-default primary background color. If you're using this API, do so as early as possible in the life of your application (such as your app delegate).
 */
+ (void)setDefaultPrimaryBackgroundColor:(UIColor *)primaryBackgroundColor;

/**
 *  The globally-default primary background color. Defaults to [UIColor colorWithRed:242.0f/255.0f green:242.0f/255.0f blue:245.0f/255.0f alpha:1].
 */
+ (UIColor *)defaultPrimaryBackgroundColor;

/**
 *  Set the globally-default secondary background color. If you're using this API, do so as early as possible in the life of your application (such as your app delegate).
 */
+ (void)setDefaultSecondaryBackgroundColor:(UIColor *)secondaryBackgroundColor;

/**
 *  The globally-default secondary background color. Defaults to [UIColor whiteColor].
 */
+ (UIColor *)defaultSecondaryBackgroundColor;

/**
 *  Set the globally-default primary text color. If you're using this API, do so as early as possible in the life of your application (such as your app delegate).
 */
+ (void)setDefaultPrimaryTextColor:(UIColor *)primaryTextColor;

/**
 *  The globally-default primary text color. Defaults to [UIColor colorWithRed:43.0f/255.0f green:43.0f/255.0f blue:45.0f/255.0f alpha:1].
 */
+ (UIColor *)defaultPrimaryTextColor;

/**
 *  Set the globally-default secondary text color. If you're using this API, do so as early as possible in the life of your application (such as your app delegate).
 */
+ (void)setDefaultSecondaryTextColor:(UIColor *)secondaryTextColor;

/**
 *  The globally-default secondary text color. Defaults to [UIColor colorWithRed:142.0f/255.0f green:142.0f/255.0f blue:147.0f/255.0f alpha:1].
 */
+ (UIColor *)defaultSecondaryTextColor;

/**
 *  The globally-default accent color.
 */
+ (void)setDefaultAccentColor:(UIColor *)accentColor;

/**
 *  The globally-default accent color. Defaults to [UIColor colorWithRed:0 green:122.0f/255.0f blue:1 alpha:1].
 */
+ (UIColor *)defaultAccentColor;

/**
 *  Set the globally-default font. If you're using this API, do so as early as possible in the life of your application (such as your app delegate).
 */
+ (void)setDefaultFont:(UIFont *)font;

/**
 *  The globally-default font. Defaults to [UIFont systemFontOfSize:17].
 */
+ (UIFont *)defaultFont;

/**
 *  When initializing an STPTheme, you may specify `nil` for any of the parameters of this method. If you do, we'll use the globally-default value for that property. For example, if you specify a nil primaryBackgroundColor, the value on the resultant STPTheme will be equal to [STPTheme defaultPrimaryBackgroundColor].
 *  @return a new STPTheme.
 */
- (instancetype)initWithPrimaryBackgroundColor:(nullable UIColor *)primaryBackgroundColor
                      secondaryBackgroundColor:(nullable UIColor *)secondaryBackgroundColor
                              primaryTextColor:(nullable UIColor *)primaryTextColor
                            secondaryTextColor:(nullable UIColor *)secondaryTextColor
                                   accentColor:(nullable UIColor *)accentColor
                                          font:(nullable UIFont *)font;

/**
 *  The primary background color of the theme. This will be used as the backgroundColor for any views with this theme.
 */
@property(nonatomic, readonly)UIColor *primaryBackgroundColor;

/**
 *  The secondary background color of this theme. This will be used as the backgroundColor for any supplemental views inside a view with this theme - for example, a UITableView will set it's cells' background color to this value.
 */
@property(nonatomic, readonly)UIColor *secondaryBackgroundColor;

/**
 *  The primary text color of this theme. This will be used as the text color for any important labels in a view with this theme (such as the text color for a text field that the user needs to fill out).
 */
@property(nonatomic, readonly)UIColor *primaryTextColor;

/**
 *  The secondary text color of this theme. This will be used as the text color for any supplementary labels in a view with this theme (such as the placeholder color for a text field that the user needs to fill out).
 */
@property(nonatomic, readonly)UIColor *secondaryTextColor;

/**
 *  This color is automatically derived from the secondaryColor with a lower alpha component, used for disabled text.
 */
@property(nonatomic, readonly)UIColor *tertiaryTextColor;

/**
 *  The accent color of this theme - it will be used for any buttons and other elements on a view that are important to highlight.
 */
@property(nonatomic, readonly)UIColor *accentColor;

/**
 *  The font to be used for all views using this theme. Make sure to select an appropriate size.
 */
@property(nonatomic, readonly)UIFont  *font;

/**
 *  This font is automatically derived from the font, with a slightly lower point size, and will be used for supplementary labels.
 */
@property(nonatomic, readonly)UIFont  *smallFont;

@end

NS_ASSUME_NONNULL_END
