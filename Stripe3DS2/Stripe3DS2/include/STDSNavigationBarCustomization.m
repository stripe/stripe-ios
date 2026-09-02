//
//  STDSNavigationBarCustomization.m
//  Stripe3DS2
//
//  Created by Andrew Harrison on 3/14/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

@import StripeCore;
#import "STDSNavigationBarCustomization.h"

NS_ASSUME_NONNULL_BEGIN

@implementation STDSNavigationBarCustomization

+ (instancetype)defaultSettings {
    return [self new];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _barTintColor = nil;
        _headerText = STPThreeDS2Localization.secureCheckout;
        _buttonText = STPThreeDS2Localization.cancel;
        _translucent = YES;
    }
    return self;
}

- (id)copyWithZone:(nullable NSZone *)zone {
    STDSNavigationBarCustomization *copy = [super copyWithZone:zone];
    copy.barTintColor = self.barTintColor;
    copy.headerText = self.headerText;
    copy.buttonText = self.buttonText;
    copy.barStyle = self.barStyle;
    copy.translucent = self.translucent;
    
    return copy;
}

@end

NS_ASSUME_NONNULL_END
