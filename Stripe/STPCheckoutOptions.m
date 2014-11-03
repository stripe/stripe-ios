//
//  STPCheckoutOptions.m
//  StripeExample
//
//  Created by Jack Flintermann on 10/6/14.
//  Copyright (c) 2014 Stripe. All rights reserved.
//

#import "STPCheckoutOptions.h"
#import "Stripe.h"

@implementation STPCheckoutOptions

- (NSString *)stringifiedJSONRepresentation {
    NSMutableDictionary *values = [NSMutableDictionary dictionary];
    if (self.publishableKey) {
        values[@"publishableKey"] = self.publishableKey;
    }
    if (self.logoURL) {
        values[@"logoURL"] = [self.logoURL absoluteString];
    }
    if (self.logoImage && !self.logoURL) {
        NSString *base64 = [UIImagePNGRepresentation(self.logoImage) base64EncodedStringWithOptions:0];
        values[@"logoImage"] = [NSString stringWithFormat:@"data:image/png;base64,%@", base64];
    }
    if (self.logoColor) {
        values[@"logoColor"] = [[self class] hexCodeForColor:self.logoColor];
    }
    if (self.companyName) {
        values[@"companyName"] = self.companyName;
    }
    if (self.purchaseDescription) {
        values[@"purchaseDescription"] = self.purchaseDescription;
    }
    if (self.purchaseLabel) {
        values[@"purchaseLabel"] = self.purchaseLabel;
    }
    if (self.purchaseCurrency) {
        values[@"purchaseCurrency"] = [self.purchaseCurrency uppercaseString];
    }
    if (self.purchaseAmount) {
        values[@"purchaseAmount"] = self.purchaseAmount;
    }
    if (self.customerEmail) {
        values[@"customerEmail"] = self.customerEmail;
    }
    if (self.enableRememberMe) {
        values[@"enableRememberMe"] = self.enableRememberMe;
    }
    if (self.enablePostalCode) {
        values[@"enablePostalCode"] = self.enablePostalCode;
    }
    
    return [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:values options:0 error:nil] encoding:NSUTF8StringEncoding];
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
