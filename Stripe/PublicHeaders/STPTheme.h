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

+ (void)setDefaultPrimaryBackgroundColor:(UIColor *)primaryBackgroundColor;
+ (UIColor *)defaultPrimaryBackgroundColor;
+ (void)setDefaultSecondaryBackgroundColor:(UIColor *)secondaryBackgroundColor;
+ (UIColor *)defaultSecondaryBackgroundColor;
+ (void)setDefaultPrimaryTextColor:(UIColor *)primaryTextColor;
+ (UIColor *)defaultPrimaryTextColor;
+ (void)setDefaultSecondaryTextColor:(UIColor *)secondaryTextColor;
+ (UIColor *)defaultSecondaryTextColor;
+ (void)setDefaultAccentColor:(UIColor *)accentColor;
+ (UIColor *)defaultAccentColor;
+ (void)setDefaultFont:(UIFont *)font;
+ (UIFont *)defaultFont;

- (instancetype)initWithPrimaryBackgroundColor:(nullable UIColor *)primaryBackgroundColor
                      secondaryBackgroundColor:(nullable UIColor *)secondaryBackgroundColor
                              primaryTextColor:(nullable UIColor *)primaryTextColor
                            secondaryTextColor:(nullable UIColor *)secondaryTextColor
                                   accentColor:(nullable UIColor *)accentColor
                                          font:(nullable UIFont *)font;

@property(nonatomic, readonly)UIColor *primaryBackgroundColor;
@property(nonatomic, readonly)UIColor *secondaryBackgroundColor;
@property(nonatomic, readonly)UIColor *primaryTextColor;
@property(nonatomic, readonly)UIColor *secondaryTextColor;
@property(nonatomic, readonly)UIColor *tertiaryTextColor;
@property(nonatomic, readonly)UIColor *accentColor;
@property(nonatomic, readonly)UIFont  *font;
@property(nonatomic, readonly)UIFont  *smallFont;

@end

NS_ASSUME_NONNULL_END
