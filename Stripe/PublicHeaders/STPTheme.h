//
//  STPTheme.h
//  Stripe
//
//  Created by Jack Flintermann on 5/3/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface STPTheme : NSObject<NSCopying>

+ (void)setDefaultTheme:(STPTheme *)theme;

+ (STPTheme *)defaultTheme;

/**
 *  When initializing an STPTheme, you may specify `nil` for any of the parameters of this method. If you do, we'll use the globally-default value for that property. For example, if you specify a nil primaryBackgroundColor, the value on the resultant STPTheme will be equal to [STPTheme defaultPrimaryBackgroundColor].
 *  @return a new STPTheme.
 */
- (instancetype)initWithPrimaryBackgroundColor:(nullable UIColor *)primaryBackgroundColor
                      secondaryBackgroundColor:(nullable UIColor *)secondaryBackgroundColor
                        primaryForegroundColor:(nullable UIColor *)primaryForegroundColor
                      secondaryForegroundColor:(nullable UIColor *)secondaryForegroundColor
                                   accentColor:(nullable UIColor *)accentColor
                                    errorColor:(nullable UIColor *)errorColor
                                          font:(nullable UIFont *)font
                                    mediumFont:(nullable UIFont *)mediumFont;

/**
 *  The primary background color of the theme. This will be used as the backgroundColor for any views with this theme.
 */
@property(nonatomic, readonly)UIColor *primaryBackgroundColor;

/**
 *  The secondary background color of this theme. This will be used as the backgroundColor for any supplemental views inside a view with this theme - for example, a UITableView will set it's cells' background color to this value.
 */
@property(nonatomic, readonly)UIColor *secondaryBackgroundColor;

@property(nonatomic, readonly)UIColor *tertiaryBackgroundColor;

@property(nonatomic, readonly)UIColor *quaternaryBackgroundColor;

/**
 *  The primary foreground color of this theme. This will be used as the text color for any important labels in a view with this theme (such as the text color for a text field that the user needs to fill out).
 */
@property(nonatomic, readonly)UIColor *primaryForegroundColor;

/**
 *  The secondary foreground color of this theme. This will be used as the text color for any supplementary labels in a view with this theme (such as the placeholder color for a text field that the user needs to fill out).
 */
@property(nonatomic, readonly)UIColor *secondaryForegroundColor;

/**
 *  This color is automatically derived from the secondaryColor with a lower alpha component, used for disabled text.
 */
@property(nonatomic, readonly)UIColor *tertiaryForegroundColor;

/**
 *  The accent color of this theme - it will be used for any buttons and other elements on a view that are important to highlight.
 */
@property(nonatomic, readonly)UIColor *accentColor;

/**
 *  The error color of this theme - it will be used for rendering any error messages or views.
 */
@property(nonatomic, readonly)UIColor *errorColor;

/**
 *  The font to be used for all views using this theme. Make sure to select an appropriate size.
 */
@property(nonatomic, readonly)UIFont  *font;

/**
 *  The medium-weight font to be used for all bold text in views using this theme. Make sure to select an appropriate size.
 */
@property(nonatomic, readonly)UIFont  *mediumFont;

/**
 *  This font is automatically derived from the font, with a slightly lower point size, and will be used for supplementary labels.
 */
@property(nonatomic, readonly)UIFont  *smallFont;

/**
 *  This font is automatically derived from the font, with a larger point size, and will be used for large labels such as SMS code entry.
 */
@property(nonatomic, readonly)UIFont  *largeFont;

@end

NS_ASSUME_NONNULL_END
