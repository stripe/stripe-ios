//
//  UIColor+DefaultColors.m
//  Stripe3DS2
//
//  Created by Andrew Harrison on 3/18/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

#import "UIColor+DefaultColors.h"
#import "UIColor+ThirteenSupport.h"

@implementation UIColor (DefaultColors)

+ (UIColor *)_stds_defaultFooterBackgroundColor {
        return [UIColor _stds_systemGray5Color];
}

+ (UIColor *)_stds_blueColor {
            return [UIColor _stds_colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull traitCollection) {
                return (traitCollection.userInterfaceStyle == UIUserInterfaceStyleLight) ? [UIColor colorWithRed:(CGFloat)(29.0 / 255.0) green:(CGFloat)(115.0 / 255.0) blue:(CGFloat)(250.0 / 255.0) alpha:1.0] : [UIColor colorWithRed:(CGFloat)(39.0 / 255.0) green:(CGFloat)(125.0 / 255.0) blue:(CGFloat)(255.0 / 255.0) alpha:1.0];
            }];
}

@end
