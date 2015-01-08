//
//  STPColorUtils.m
//  Stripe
//
//  Created by Jack Flintermann on 11/3/14.
//
//

#import "STPColorUtils.h"

@implementation STPColorUtils

// Some of this code is adapted from https://github.com/nicklockwood/ColorUtils

+ (BOOL)colorIsLight:(STP_COLOR_CLASS *)color {
    CGColorSpaceModel model = CGColorSpaceGetModel(CGColorGetColorSpace(color.CGColor));
    const CGFloat *components = CGColorGetComponents(color.CGColor);
    switch (model) {
    case kCGColorSpaceModelMonochrome: {
        return components[1] > 0.5;
    }
    case kCGColorSpaceModelRGB: {
        CGFloat colorBrightness = ((components[0] * 299) + (components[1] * 587) + (components[2] * 114)) / 1000;
        return colorBrightness > 0.5;
    }
    default: { return YES; }
    }
}

+ (STP_COLOR_CLASS *)colorForHexCode:(NSString *)aHexCode {
    NSString *hexCode = [aHexCode stringByReplacingOccurrencesOfString:@"#" withString:@""];
    if (hexCode.length != 6) {
        return [STP_COLOR_CLASS blackColor];
    }
    uint32_t rgb;
    NSScanner *scanner = [NSScanner scannerWithString:hexCode];
    [scanner scanHexInt:&rgb];
    CGFloat red = ((rgb & 0xFF0000) >> 16) / 255.0f;
    CGFloat green = ((rgb & 0x00FF00) >> 8) / 255.0f;
    CGFloat blue = (rgb & 0x0000FF) / 255.0f;
    return [STP_COLOR_CLASS colorWithRed:red green:green blue:blue alpha:1.0f];
}

+ (NSString *)hexCodeForColor:(STP_COLOR_CLASS *)color {
    uint8_t rgb[3];
    CGColorSpaceModel model = CGColorSpaceGetModel(CGColorGetColorSpace(color.CGColor));
    const CGFloat *components = CGColorGetComponents(color.CGColor);
    switch (model) {
    case kCGColorSpaceModelMonochrome: {
        rgb[0] = (uint8_t)(components[0] * 255);
        rgb[1] = (uint8_t)(components[0] * 255);
        rgb[2] = (uint8_t)(components[0] * 255);
        break;
    }
    case kCGColorSpaceModelRGB: {
        rgb[0] = (uint8_t)(components[0] * 255);
        rgb[1] = (uint8_t)(components[1] * 255);
        rgb[2] = (uint8_t)(components[2] * 255);
        break;
    }
    default: {
        rgb[0] = 0;
        rgb[1] = 0;
        rgb[2] = 0;
        break;
    }
    }
    unsigned long rgbValue = (unsigned long)((rgb[0] << 16) + (rgb[1] << 8) + rgb[2]);
    return [NSString stringWithFormat:@"#%.6lx", rgbValue];
}

@end
