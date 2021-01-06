//
//  UIColor+ThirteenSupport.m
//  Stripe3DS2
//
//  Created by David Estes on 8/21/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

#import "UIColor+ThirteenSupport.h"

@implementation UIColor (STDSThirteenSupport)

+ (UIColor *)_stds_colorWithDynamicProvider:(UIColor * _Nonnull (^)(UITraitCollection *traitCollection))dynamicProvider {
    if (@available(iOS 13.0, *)) {
      return [UIColor colorWithDynamicProvider:dynamicProvider];
    } else {
      return dynamicProvider([[UITraitCollection alloc] init]);
    }
}

+ (UIColor *)_stds_systemGray5Color {
    if (@available(iOS 13.0, *)) {
      return [UIColor systemGray5Color];
    } else {
      return [UIColor colorWithRed:(CGFloat)229.0/(CGFloat)255.0 green:(CGFloat)229.0/(CGFloat)255.0 blue:(CGFloat)234.0/(CGFloat)255.0 alpha:1.0];
    }
}

+ (UIColor *)_stds_systemGray2Color {
    if (@available(iOS 13.0, *)) {
      return [UIColor systemGray2Color];
    } else {
      return [UIColor colorWithRed:(CGFloat)174.0/(CGFloat)255.0 green:(CGFloat)174.0/(CGFloat)255.0 blue:(CGFloat)178.0/(CGFloat)255.0 alpha:1.0];
    }
}

+ (UIColor *)_stds_systemBackgroundColor {
    if (@available(iOS 13.0, *)) {
      return [UIColor systemBackgroundColor];
    } else {
      return [UIColor whiteColor];
    }
}

+ (UIColor *)_stds_labelColor {
    if (@available(iOS 13.0, *)) {
      return [UIColor labelColor];
    } else {
      return [UIColor blackColor];
    }
}

@end

void _stds_import_uicolor_thirteensupport(void) {}
