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

- (instancetype)init {
    self = [super init];
    if (self) {
        _publishableKey = [Stripe defaultPublishableKey];
        _currency = @"USD";
        _validateZipCode = NO;
        _allowRememberMe = YES;
    }
    return self;
}

- (NSString *)stringifiedJavaScriptRepresentation {
    NSMutableDictionary *values = [NSMutableDictionary dictionary];
    if (self.publishableKey) {
        values[@"key"] = self.publishableKey;
    }
    if (self.logoImage && !self.logoImageURL) {
        NSString *base64 = [UIImagePNGRepresentation(self.logoImage) base64EncodedStringWithOptions:0];
        values[@"image"] = [NSString stringWithFormat:@"data:image/png;base64,%@", base64];
    }
    if (self.logoImageURL) {
        values[@"image"] = [self.logoImageURL absoluteString];
    }
    if (self.headerBackgroundColor) {
        values[@"color"] = [[self class] hexCodeForColor:self.headerBackgroundColor];
    }
    if (self.companyName) {
        values[@"name"] = self.companyName;
    }
    if (self.productDescription) {
        values[@"description"] = self.productDescription;
    }
    if (self.purchaseAmount) {
        values[@"amount"] = @(self.purchaseAmount);
    }
    if (self.currency) {
        values[@"currency"] = [self.currency uppercaseString];
    }
    if (self.panelLabel) {
        values[@"panelLabel"] = self.panelLabel;
    }
    if (self.customerEmail) {
        values[@"email"] = self.customerEmail;
    }
    
    values[@"allowRememberMe"] = @(self.allowRememberMe);
    values[@"zipCode"] = @(self.validateZipCode);
    
    return [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:values options:0 error:nil] encoding:NSUTF8StringEncoding];
}

+ (NSString *)hexCodeForColor:(UIColor *)color {
    CGFloat rgba[4];
    CGColorSpaceModel model = CGColorSpaceGetModel(CGColorGetColorSpace(color.CGColor));
    const CGFloat *components = CGColorGetComponents(color.CGColor);
    switch (model) {
        case kCGColorSpaceModelMonochrome: {
            rgba[0] = components[0];
            rgba[1] = components[0];
            rgba[2] = components[0];
            rgba[3] = components[1];
            break;
        }
        case kCGColorSpaceModelRGB: {
            rgba[0] = components[0];
            rgba[1] = components[1];
            rgba[2] = components[2];
            rgba[3] = components[3];
            break;
        }
        default: {
            rgba[0] = 0;
            rgba[1] = 0;
            rgba[2] = 0;
            rgba[3] = 1.0f;
            break;
        }
    }
    uint8_t red = rgba[0]*255;
    uint8_t green = rgba[1]*255;
    uint8_t blue = rgba[2]*255;
    uint8_t alpha = rgba[3]*255;
    unsigned long rgbaValue = (red << 24) + (green << 16) + (blue << 8) + alpha;
    return [NSString stringWithFormat:@"#%.8lx", rgbaValue];
}

@end
