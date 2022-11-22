//
//  STDSFooterCustomization.m
//  Stripe3DS2
//
//  Created by Yuki Tokuhiro on 6/10/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

#import "STDSFooterCustomization.h"

#import "UIFont+DefaultFonts.h"
#import "UIColor+DefaultColors.h"
#import "UIColor+ThirteenSupport.h"

@implementation STDSFooterCustomization

+ (instancetype)defaultSettings {
    return [self new];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.textColor = UIColor._stds_labelColor;
        _headingTextColor = UIColor._stds_labelColor;
        _backgroundColor = [UIColor _stds_defaultFooterBackgroundColor];
        _chevronColor = [UIColor _stds_systemGray2Color];
        self.font = [UIFont _stds_defaultLabelTextFontWithScale:(CGFloat)0.9];
        _headingFont = [UIFont _stds_defaultLabelTextFontWithScale:(CGFloat)0.9];
    }
    return self;
}

- (instancetype)copyWithZone:(nullable NSZone *)zone {
    STDSFooterCustomization *copy = [super copyWithZone:zone];
    copy.headingTextColor = self.headingTextColor;
    copy.headingFont = self.headingFont;
    copy.backgroundColor = self.backgroundColor;
    copy.chevronColor = self.chevronColor;
    
    return copy;
}


@end
