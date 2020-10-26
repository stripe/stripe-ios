//
//  STPThreeDSLabelCustomization.m
//  StripeiOS
//
//  Created by Yuki Tokuhiro on 6/17/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import "STPThreeDSLabelCustomization.h"

#import "STPThreeDSCustomization+Private.h"
#import <Stripe/STDSLabelCustomization.h>

@implementation STPThreeDSLabelCustomization

+ (instancetype)defaultSettings {
    return [STPThreeDSLabelCustomization new];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _labelCustomization = [STDSLabelCustomization defaultSettings];
    }
    return self;
}

- (UIFont *)headingFont {
    return self.labelCustomization.headingFont;
}

- (void)setHeadingFont:(UIFont *)headingFont {
    self.labelCustomization.headingFont = headingFont;
}

- (UIColor *)headingTextColor {
    return self.labelCustomization.headingTextColor;
}

- (void)setHeadingTextColor:(UIColor *)headingTextColor {
    self.labelCustomization.headingTextColor = headingTextColor;
}

- (UIFont *)font {
    return self.labelCustomization.font;
}

- (void)setFont:(UIFont *)font {
    self.labelCustomization.font = font;
}

- (UIColor *)textColor {
    return self.labelCustomization.textColor;
}

- (void)setTextColor:(UIColor *)textColor {
    self.labelCustomization.textColor = textColor;
}

@end
