//
//  STPThreeDSNavigationBarCustomization.m
//  StripeiOS
//
//  Created by Yuki Tokuhiro on 6/17/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import "STPThreeDSNavigationBarCustomization.h"

#import "STPThreeDSCustomization+Private.h"
#import <Stripe/STDSNavigationBarCustomization.h>

@implementation STPThreeDSNavigationBarCustomization

+ (instancetype)defaultSettings {
    return [STPThreeDSNavigationBarCustomization new];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _navigationBarCustomization = [STDSNavigationBarCustomization defaultSettings];
    }
    return self;
}

- (UIColor *)barTintColor {
    return self.navigationBarCustomization.barTintColor;
}

- (void)setBarTintColor:(UIColor *)barTintColor {
    self.navigationBarCustomization.barTintColor = barTintColor;
}

- (UIBarStyle)barStyle {
    return self.navigationBarCustomization.barStyle;
}

- (void)setBarStyle:(UIBarStyle)barStyle {
    self.navigationBarCustomization.barStyle = barStyle;
}


- (BOOL)isTranslucent {
    return self.navigationBarCustomization.translucent;
}

- (void)setTranslucent:(BOOL)translucent {
    self.navigationBarCustomization.translucent = translucent;
}

- (NSString *)headerText {
    return self.navigationBarCustomization.headerText;
}

- (void)setHeaderText:(NSString *)headerText {
    self.navigationBarCustomization.headerText = headerText;
}

- (NSString *)buttonText {
    return self.navigationBarCustomization.buttonText;
}

- (void)setButtonText:(NSString *)buttonText {
    self.navigationBarCustomization.buttonText = buttonText;
}

- (UIFont *)font {
    return self.navigationBarCustomization.font;
}

- (void)setFont:(UIFont *)font {
    self.navigationBarCustomization.font = font;
}

- (UIColor *)textColor {
    return self.navigationBarCustomization.textColor;
}

- (void)setTextColor:(UIColor *)textColor {
    self.navigationBarCustomization.textColor = textColor;
}

@end
