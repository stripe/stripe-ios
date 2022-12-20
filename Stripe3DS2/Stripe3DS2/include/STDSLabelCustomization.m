//
//  STDSLabelCustomization.m
//  Stripe3DS2
//
//  Created by Andrew Harrison on 3/14/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

#import "STDSLabelCustomization.h"

#import "UIFont+DefaultFonts.h"
#import "UIColor+ThirteenSupport.h"

NS_ASSUME_NONNULL_BEGIN

@implementation STDSLabelCustomization

+ (instancetype)defaultSettings {
    return [self new];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.textColor = UIColor._stds_labelColor;
        _headingTextColor = UIColor._stds_labelColor;
        self.font = [UIFont _stds_defaultLabelTextFontWithScale:(CGFloat)0.9];
        _headingFont = [UIFont _stds_defaultHeadingTextFont];
    }
    return self;
}

- (id)copyWithZone:(nullable NSZone *)zone {
    STDSLabelCustomization *copy = [super copyWithZone:zone];
    copy.headingTextColor = self.headingTextColor;
    copy.headingFont = self.headingFont;

    return copy;
}

@end

NS_ASSUME_NONNULL_END
