//
//  STPThreeDSLabelCustomization.h
//  StripeiOS
//
//  Created by Yuki Tokuhiro on 6/17/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

@import UIKit;

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 A customization object to use to configure the UI of a text label.
 */
@interface STPThreeDSLabelCustomization : NSObject

/// The default settings.
+ (instancetype)defaultSettings;

/// The font to use for heading text.
@property (nonatomic, strong) UIFont *headingFont;

/// The color of heading text. Defaults to black.
@property (nonatomic, strong) UIColor *headingTextColor;

/// The font to use for non-heading text.
@property (nonatomic, strong) UIFont *font;

/// The color to use for non-heading text. Defaults to black.
@property (nonatomic, strong) UIColor *textColor;

@end

NS_ASSUME_NONNULL_END
