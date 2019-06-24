//
//  STPThreeDSSelectionCustomization.h
//  StripeiOS
//
//  Created by Yuki Tokuhiro on 6/18/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

@import UIKit;

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 A customization object that configures the appearance of
 radio buttons and checkboxes.
 */
@interface STPThreeDSSelectionCustomization : NSObject

/// The default settings.
+ (instancetype)defaultSettings;

/**
 The primary color of the selected state.
 Defaults to blue.
 */
@property (nonatomic) UIColor *primarySelectedColor;

/**
 The secondary color of the selected state (e.g. the checkmark color).
 Defaults to white.
 */
@property (nonatomic) UIColor *secondarySelectedColor;

/**
 The background color displayed in the unselected state.
 Defaults to light blue.
 */
@property (nonatomic) UIColor *unselectedBackgroundColor;

/**
 The color of the border drawn around the view in the unselected state.
 Defaults to blue.
 */
@property (nonatomic) UIColor *unselectedBorderColor;

@end

NS_ASSUME_NONNULL_END
