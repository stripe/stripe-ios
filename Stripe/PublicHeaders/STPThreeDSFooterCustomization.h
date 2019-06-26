//
//  STPThreeDSFooterCustomization.h
//  StripeiOS
//
//  Created by Yuki Tokuhiro on 6/17/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

@import UIKit;

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 The Challenge view displays a footer with additional details that
 expand when tapped. This object configures the appearance of that view.
 */
@interface STPThreeDSFooterCustomization : NSObject

/// The default settings.
+ (instancetype)defaultSettings;

/**
 The background color of the footer.
 Defaults to gray.
 */
@property (nonatomic, strong) UIColor *backgroundColor;

/// The color of the chevron. Defaults to a dark gray.
@property (nonatomic, strong) UIColor *chevronColor;

/// The color of the heading text. Defaults to black.
@property (nonatomic, strong) UIColor *headingTextColor;

/// The font to use for the heading text.
@property (nonatomic, strong) UIFont *headingFont;

/// The font of the text.
@property (nonatomic, strong) UIFont *font;

/// The color of the text.
@property (nonatomic, strong) UIColor *textColor;

@end

NS_ASSUME_NONNULL_END
