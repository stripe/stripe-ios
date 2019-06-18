//
//  STPThreeDSNavigationBarCustomization.h
//  StripeiOS
//
//  Created by Yuki Tokuhiro on 6/17/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

@import UIKit;

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 A customization object to use to configure a UINavigationBar.
 */
@interface STPThreeDSNavigationBarCustomization : NSObject

/// The default settings.
+ (instancetype)defaultSettings;

/**
 The tint color of the navigation bar background.
 Defaults to nil.
 */
@property (nonatomic, nullable) UIColor *barTintColor;

/**
 The navigation bar style.
 Defaults to UIBarStyleDefault.
 */
@property (nonatomic) UIBarStyle barStyle;

/**
 A Boolean value indicating whether the navigation bar is translucent or not.
 Defaults to YES.
 */
@property (nonatomic, getter=isTranslucent) BOOL translucent;

/**
 The text to display in the title of the navigation bar.
 Defaults to "Secure checkout".
 */
@property (nonatomic, copy) NSString *headerText;

/**
 The text to display for the button in the navigation bar.
 Defaults to "Cancel".
 */
@property (nonatomic, copy) NSString *buttonText;

/// The font to use for the title. Defaults to nil.
@property (nonatomic, nullable) UIFont *font;

/// The color to use for the title. Defaults to nil.
@property (nonatomic, nullable) UIColor *textColor;

@end

NS_ASSUME_NONNULL_END
