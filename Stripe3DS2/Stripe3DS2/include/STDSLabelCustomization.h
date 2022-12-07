//
//  STDSLabelCustomization.h
//  Stripe3DS2
//
//  Created by Andrew Harrison on 3/14/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

#import "STDSCustomization.h"

NS_ASSUME_NONNULL_BEGIN

/**
 A customization object to use to configure the UI of a text label.
 
 The font and textColor inherited from `STDSCustomization` configure non-heading labels.
 */
@interface STDSLabelCustomization : STDSCustomization

/// The default settings.
+ (instancetype)defaultSettings;

/// The color of the heading text. Defaults to black.
@property (nonatomic) UIColor *headingTextColor;

/// The font to use for the heading text.
@property (nonatomic) UIFont *headingFont;

@end

NS_ASSUME_NONNULL_END
