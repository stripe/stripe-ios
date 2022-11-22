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
            if (@available(iOS 12.0, *)) {
                return [UIColor _stds_colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull traitCollection) {
                    return (traitCollection.userInterfaceStyle == UIUserInterfaceStyleLight) ? [UIColor colorWithRed:(CGFloat)(29.0 / 255.0) green:(CGFloat)(115.0 / 255.0) blue:(CGFloat)(250.0 / 255.0) alpha:1.0] : [UIColor colorWithRed:(CGFloat)(39.0 / 255.0) green:(CGFloat)(125.0 / 255.0) blue:(CGFloat)(255.0 / 255.0) alpha:1.0];
                }];
            } else {
                CGFloat redValue = (CGFloat)29.0 / (CGFloat)255.0;
                CGFloat greenValue = (CGFloat)115.0 / (CGFloat)255.0;
                CGFloat blueValue = (CGFloat)250.0 / (CGFloat)255.0;
                return [UIColor colorWithRed:redValue green:greenValue blue:blueValue alpha:1.0];
            }
}

@end

void _stds_import_uicolor_defaultcolors() { }
