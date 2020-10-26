//
//  STPColorUtils.m
//  Stripe
//
//  Created by Jack Flintermann on 5/16/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import "STPColorUtils.h"

@implementation STPColorUtils

+ (CGFloat)perceivedBrightnessForColor:(UIColor *)color {
    CGFloat red, green, blue;
    if ([color getRed:&red green:&green blue:&blue alpha:nil]) {
        // We're using the luma value from YIQ
        // https://en.wikipedia.org/wiki/YIQ#From_RGB_to_YIQ
        // recommended by https://www.w3.org/WAI/ER/WD-AERT/#color-contrast
        return red * (CGFloat)0.299 + green * (CGFloat)0.587 + blue * (CGFloat)0.114;
    } else {
        // Couldn't get RGB for this color, device couldn't convert it from whatever
        // colorspace it's in.
        // Make it "bright", since most of the color space is (based on our current
        // formula), but not very bright.
        return (CGFloat)0.4;
    }
}

+ (UIColor *)brighterColor:(UIColor *)color1 color2:(UIColor *)color2 {
    CGFloat brightness1 = [self perceivedBrightnessForColor:color1];
    CGFloat brightness2 = [self perceivedBrightnessForColor:color2];
    return brightness1 >= brightness2 ? color1 : color2;
}

+ (BOOL)colorIsBright:(UIColor *)color {
    return [self perceivedBrightnessForColor:color] > 0.3;
}

@end
