//
//  STPThreeDSFooterCustomization.m
//  StripeiOS
//
//  Created by Yuki Tokuhiro on 6/17/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import "STPThreeDSFooterCustomization.h"

#import "STPThreeDSCustomization+Private.h"
#import <Stripe/STDSFooterCustomization.h>

@implementation STPThreeDSFooterCustomization

+ (instancetype)defaultSettings {
    return [STPThreeDSFooterCustomization new];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _footerCustomization = [STDSFooterCustomization defaultSettings];
    }
    return self;
}

- (UIColor *)backgroundColor {
    return self.footerCustomization.backgroundColor;
}

- (void)setBackgroundColor:(UIColor *)backgroundColor {
    self.footerCustomization.backgroundColor = backgroundColor;
}

- (UIColor *)chevronColor {
    return self.footerCustomization.chevronColor;
}

- (void)setChevronColor:(UIColor *)chevronColor {
    self.footerCustomization.chevronColor = chevronColor;
}

- (UIColor *)headingTextColor {
    return self.footerCustomization.headingTextColor;
}

- (void)setHeadingTextColor:(UIColor *)headingTextColor {
    self.footerCustomization.headingTextColor = headingTextColor;
}

- (UIFont *)headingFont {
    return self.footerCustomization.headingFont;
}

- (void)setHeadingFont:(UIFont *)headingFont {
    self.footerCustomization.headingFont = headingFont;
}

- (UIFont *)font {
    return self.footerCustomization.font;
}

- (void)setFont:(UIFont *)font {
    self.footerCustomization.font = font;
}

- (UIColor *)textColor {
    return self.footerCustomization.textColor;
}

- (void)setTextColor:(UIColor *)textColor {
    self.footerCustomization.textColor = textColor;
}

@end
