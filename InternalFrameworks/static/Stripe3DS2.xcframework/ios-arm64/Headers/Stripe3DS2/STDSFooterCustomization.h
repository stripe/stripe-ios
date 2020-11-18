//
//  STDSFooterCustomization.h
//  Stripe3DS2
//
//  Created by Yuki Tokuhiro on 6/10/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "STDSCustomization.h"

NS_ASSUME_NONNULL_BEGIN

/**
 The Challenge view displays a footer with additional details that
 expand when tapped. This object configures the appearance of that view.
*/
@interface STDSFooterCustomization : STDSCustomization

/// The default settings.
+ (instancetype)defaultSettings;

/**
 The background color of the footer.
 Defaults to gray.
 */
@property (nonatomic) UIColor *backgroundColor;

/// The color of the chevron. Defaults to a dark gray.
@property (nonatomic) UIColor *chevronColor;

/// The color of the heading text. Defaults to black.
@property (nonatomic) UIColor *headingTextColor;

/// The font to use for the heading text.
@property (nonatomic) UIFont *headingFont;

@end

NS_ASSUME_NONNULL_END
