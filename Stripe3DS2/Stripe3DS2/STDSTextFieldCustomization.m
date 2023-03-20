//
//  STDSTextFieldCustomization.m
//  Stripe3DS2
//
//  Created by Andrew Harrison on 3/14/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

#import "STDSTextFieldCustomization.h"

#import "UIFont+DefaultFonts.h"
#import "UIColor+ThirteenSupport.h"

NS_ASSUME_NONNULL_BEGIN

@implementation STDSTextFieldCustomization

+ (instancetype)defaultSettings {
    return [self new];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.font = [UIFont _stds_defaultLabelTextFontWithScale:(CGFloat)1.9];
        _borderWidth = 2;
        _cornerRadius = 8;
        _keyboardAppearance = UIKeyboardAppearanceDefault;
        
        self.textColor = UIColor._stds_labelColor;
        _borderColor = UIColor.clearColor;
        _placeholderTextColor = UIColor._stds_systemGray2Color;
    }
    return self;
}

- (id)copyWithZone:(nullable NSZone *)zone {
    STDSTextFieldCustomization *copy = [super copyWithZone:zone];
    copy.borderWidth = self.borderWidth;
    copy.borderColor = self.borderColor;
    copy.cornerRadius = self.cornerRadius;
    copy.keyboardAppearance = self.keyboardAppearance;
    copy.placeholderTextColor = self.placeholderTextColor;
    
    return copy;
}

@end

NS_ASSUME_NONNULL_END
