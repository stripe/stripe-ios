//
//  STPThreeDSCustomizationSettings.m
//  StripeiOS
//
//  Created by Cameron Sabol on 5/30/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import "STPThreeDSCustomizationSettings.h"

#import <Stripe3DS2/Stripe3DS2.h>

NS_ASSUME_NONNULL_BEGIN

@implementation STPThreeDSCustomizationSettings

- (instancetype)init {
    self = [super init];
    if (self) {
        _uiCustomization = [STDSUICustomization defaultSettings];
        _authenticationTimeout = 10*60;
    }
    return self;
}

+ (instancetype)defaultSettings {
    return [[STPThreeDSCustomizationSettings alloc] init];
}

@end

NS_ASSUME_NONNULL_END
