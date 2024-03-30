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
    return [UIColor colorWithDynamicProvider:dynamicProvider];
}

+ (UIColor *)_stds_systemGray5Color {
    return [UIColor systemGray5Color];
}

+ (UIColor *)_stds_systemGray2Color {
    return [UIColor systemGray2Color];
}

+ (UIColor *)_stds_systemBackgroundColor {
    return [UIColor systemBackgroundColor];
}

+ (UIColor *)_stds_labelColor {
    return [UIColor labelColor];
}

@end
