//
//  STPColorUtils.m
//  Stripe
//
//  Created by Jack Flintermann on 11/3/14.
//
//

#import "STPColorUtils.h"

@implementation STPColorUtils

+ (BOOL)colorIsLight:(UIColor *)color {
    const CGFloat *componentColors = CGColorGetComponents(color.CGColor);
    CGFloat colorBrightness = ((componentColors[0] * 299) + (componentColors[1] * 587) + (componentColors[2] * 114)) / 1000;
    return colorBrightness > 0.5;
}

// These methods are adapted from https://github.com/nicklockwood/ColorUtils

+ (UIColor *)colorForHexCode:(NSString *)hexCode {
    hexCode = [hexCode stringByReplacingOccurrencesOfString:@"#" withString:@""];
    if (hexCode.length != 6) {
        return [UIColor blackColor];
    }
    uint32_t rgba;
    NSScanner *scanner = [NSScanner scannerWithString:hexCode];
    [scanner scanHexInt:&rgba];
    CGFloat red = ((rgba & 0xFF0000) >> 24) / 255.0f;
    CGFloat green = ((rgba & 0x00FF00) >> 16) / 255.0f;
    CGFloat blue = ((rgba & 0x0000FF) >> 8) / 255.0f;
    return [[UIColor alloc] initWithRed:red green:green blue:blue alpha:1.0f];
}

+ (NSString *)hexCodeForColor:(UIColor *)color {
    CGFloat rgb[3];
    CGColorSpaceModel model = CGColorSpaceGetModel(CGColorGetColorSpace(color.CGColor));
    const CGFloat *components = CGColorGetComponents(color.CGColor);
    switch (model) {
        case kCGColorSpaceModelMonochrome: {
            rgb[0] = components[0];
            rgb[1] = components[0];
            rgb[2] = components[0];
            break;
        }
        case kCGColorSpaceModelRGB: {
            rgb[0] = components[0];
            rgb[1] = components[1];
            rgb[2] = components[2];
            break;
        }
        default: {
            rgb[0] = 0;
            rgb[1] = 0;
            rgb[2] = 0;
            break;
        }
    }
    uint8_t red = rgb[0]*255;
    uint8_t green = rgb[1]*255;
    uint8_t blue = rgb[2]*255;
    unsigned long rgbValue = (red << 16) + (green << 8) + blue;
    return [NSString stringWithFormat:@"#%.6lx", rgbValue];
}

@end
